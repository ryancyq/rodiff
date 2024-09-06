# frozen_string_literal: true

require "open-uri"
require "json"
require "fileutils"
require "logger"
require "rodiff/config"
require "rodiff/version"

module Rodiff
  class Github
    GITHUB_API_RELEASES_URL = "https://api.github.com/repos/dmtrKovalenko/odiff/releases"
    VERSION_REGEX = %r{.*?(?<version>\d+\.\d+\.\d+)}

    def download
      fetch_metadata
      find_compatible_binaries
      download_binary
    end

    attr_reader :metadata, :binaries

    def fetch_metadata
      uri = URI.parse(GITHUB_API_RELEASES_URL)
      response = uri.open(redirect: false, read_timeout: 3, open_timeout: 5).read
      @metadata = JSON.parse(response)
    rescue StandardError => e
      abort("Failed to fetch the releases info: #{e.message}")
    end

    def find_compatible_binaries
      binary_name = platform_binary_name
      @binaries = []
      Array(metadata).each do |release|
        next if release["prerelease"]

        matched = VERSION_REGEX.match(release["tag_name"])
        next unless matched[:version]
        next unless Rodiff.compatible_odiff_version(matched[:version])

        release["assets"].each do |asset|
          next unless asset["name"] == binary_name

          binaries << { version: matched[:version], url: asset["browser_download_url"] }
        end
      end

      abort("No binary (#{binary_name}) found for #{Config.host_os}(#{Config.host_arch})") if binaries.empty?
    end

    def platform_binary_name
      case Config.host_os
      when %r{linux}
        "odiff-linux-x64.exe"
      when %r{darwin}
        Config.host_arch.include?("x86_64") ? "odiff-macos-x64.exe" : "odiff-macos-arm64.exe"
      when %r{mswin|mingw|cygwin}
        "odiff-windows-x64.exe"
      end
    end

    def download_binary
      binary_url = Array(binaries).max_by { |binary| binary[:version] }&.dig(:url)

      FileUtils.mkdir_p(Config.executable_dir) unless File.directory?(Config.executable_dir)

      executable_path = Config.executable_path
      uri = URI.parse(binary_url)
      uri.open(redirect: true, read_timeout: 3, open_timeout: 5) do |stream|
        File.binwrite(executable_path, stream.read)
      end

      chmod_executable(executable_path) if unix_based?
    rescue StandardError => e
      abort("Failed to download binary: #{e.message}")
    end

    def unix_based?
      Config.host_os =~ %r{linux|darwin}
    end

    private

    def chmod_executable(executable_path)
      FileUtils.chmod("u=rwx,go=rx", executable_path)
    end
  end
end
