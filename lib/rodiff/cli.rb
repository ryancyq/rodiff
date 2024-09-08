# frozen_string_literal: true

require "rodiff/odiff"

module Rodiff
  class CLI
    DEFAULT_DIR = File.expand_path(File.join(__dir__, "..", "..", "exe"))

    class CommandError < StandardError; end

    class UnsupportedPlatform < CommandError
      def initialize(platform)
        super(
          <<~MSG
            odiff does not support the #{platform} platform
            Please install odiff following instructions at https://github.com/dmtrKovalenko/odiff#installation
          MSG
        )
      end
    end

    class ExecutableNotFound < CommandError
      def initialize(platform, exe_path)
        super(
          <<~MSG
            Cannot find the odiff executable for #{platform} in #{exe_path}

            If you're using bundler, please make sure you're on the latest bundler version:

                gem install bundler
                bundle update --bundler

            Then make sure your lock file includes this platform by running:

                bundle lock --add-platform #{platform}
                bundle install

            See `bundle lock --help` output for details.
          MSG
          )
      end
    end

    class InstallDirectoryNotFound < CommandError
      def initialize(install_dir)
        super("ODIFF_INSTALL_DIR is set to #{install_dir}, but that directory does not exist.")
      end
    end

    class << self
      def platform
        %i[cpu os].map { |m| Gem::Platform.local.public_send(m) }.join("-")
      end

      def supported_platform?(platform = nil)
        return Gem::Platform.match_gem?(Gem::Platform.new(platform), "rodiff") unless platform.nil?

        Rodiff::Odiff::PLATFORMS.keys.any? { |p| Gem::Platform.match_gem?(Gem::Platform.new(p), "rodiff") }
      end

      def executable(exe_path: DEFAULT_DIR)
        if (odiff_install_dir = ENV.fetch("ODIFF_INSTALL_DIR", nil))
          raise InstallDirectoryNotFound, odiff_install_dir unless File.directory?(odiff_install_dir)

          warn "NOTE: using ODIFF_INSTALL_DIR to find odiff executable: #{odiff_install_dir}"
          exe_path = odiff_install_dir
          exe_file = File.expand_path(File.join(odiff_install_dir, "odiff"))
        else
          raise UnsupportedPlatform, platform unless supported_platform?

          exe_files_of_platforms = File.expand_path(File.join(exe_path, "*", "odiff"))
          exe_file = Dir.glob(exe_files_of_platforms).find do |f|
            supported_platform?(File.basename(File.dirname(f)))
          end
        end

        raise ExecutableNotFound.new(platform, exe_path) if exe_file.nil? || !File.exist?(exe_file)

        exe_file
      end
    end
  end
end
