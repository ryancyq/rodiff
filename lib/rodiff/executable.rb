# frozen_string_literal: true

require "rodiff/odiff"

module Rodiff
  class Executable
    DEFAULT_DIR = File.expand_path(File.join(__dir__, "..", "..", "exe"))
    LOCAL_INSTALL_DIR_ENV = "ODIFF_INSTALL_DIR"

    class ExecutableError < StandardError; end

    class UnsupportedPlatform < ExecutableError
      def initialize(platform)
        super(
          <<~MSG
            odiff does not support the #{platform} platform
            Please install odiff following instructions at https://github.com/dmtrKovalenko/odiff#installation
          MSG
        )
      end
    end

    class ExecutableNotFound < ExecutableError
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

            If you're still seeing this message after taking those steps, try running
            `bundle config` and ensure `force_ruby_platform` isn't set to `true`. See
            https://github.com/ryancyq/rodiff#check-bundle_force_ruby_platform
            for more details.
          MSG
          )
      end
    end

    class InstallDirectoryNotFound < ExecutableError
      def initialize(install_dir)
        super("#{LOCAL_INSTALL_DIR_ENV} is set to #{install_dir}, but that directory does not exist.")
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

      def resolve(exe_path: DEFAULT_DIR)
        if (odiff_install_dir = ENV.fetch(LOCAL_INSTALL_DIR_ENV, nil))
          exe_path = odiff_install_dir
          exe_file = expand_local_install_dir(odiff_install_dir)
        elsif supported_platform?
          exe_file = expand_bundled_dir(exe_path)
        else
          raise UnsupportedPlatform, platform
        end

        raise ExecutableNotFound.new(platform, exe_path) if exe_file.nil? || !File.exist?(exe_file)

        exe_file
      end

      private

      def expand_local_install_dir(local_install_dir)
        raise InstallDirectoryNotFound, local_install_dir unless File.directory?(local_install_dir)

        warn "NOTE: using #{LOCAL_INSTALL_DIR_ENV} to find odiff executable: #{local_install_dir}"
        exe_files = File.expand_path(File.join(local_install_dir, "odiff{,.exe}"))
        Dir.glob(exe_files).first
      end

      def expand_bundled_dir(bundled_dir)
        exe_files_of_platforms = File.expand_path(File.join(bundled_dir, "*", "odiff"))
        Dir.glob(exe_files_of_platforms).find do |f|
          supported_platform?(File.basename(File.dirname(f)))
        end
      end
    end
  end
end
