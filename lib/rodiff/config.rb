# frozen_string_literal: true

require "rbconfig"

module Rodiff
  class Config
    class << self
      def configure
        yield self
      end

      def host_os
        RbConfig::CONFIG["host_os"]
      end

      def host_arch
        RbConfig::CONFIG["arch"]
      end

      attr_writer :executable_dir, :executable_name

      def executable_dir
        @executable_dir || determine_executable_dir
      end

      def executable_name
        @executable_name || determine_executable_name
      end

      def executable_path
        File.join(executable_dir, executable_name)
      end

      private

      def determine_executable_dir
        case host_os
        when %r{linux}, %r{darwin}
          "/usr/local/bin"
        when %r{mswin|mingw|cygwin}
          File.join(Dir.home, "AppData", "Local", "odiff")
        else
          raise "Unsupported OS: #{host_os}"
        end
      end

      def determine_executable_name
        case host_os
        when %r{linux}, %r{darwin}
          "odiff"
        when %r{mswin|mingw|cygwin}
          "odiff.exe"
        else
          raise "Unsupported OS: #{host_os}"
        end
      end
    end
  end
end
