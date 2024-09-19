# frozen_string_literal: true

require "thor"
require "open3"

require "rodiff/configuration"
require "rodiff/version"

module Rodiff
  class CLI < Thor
    package_name "rodiff"

    default_command :compare

    desc "version", "Print version"
    map "-v" => :version
    method_option :odiff, type: :boolean, required: false
    def version
      if options.odiff?
        odiff_exec("--version")
      else
        say Rodiff::VERSION
      end
    end

    desc "compare [BASELINE] [VARIANT] [DIFF]", "Compare VARIANT against BASELINE, output to DIFF"
    method_option :verbose, type: :boolean, default: false
    def compare(baseline = nil, variant = nil, diff = nil)
      all_present, all_absent = args_presence(baseline, variant, diff)
      raise ArgumentError, "BASELINE, VARIANT, DIFF must be provided" unless all_present ^ all_absent

      odiff_exec(baseline, variant, diff)
    end

    def self.exit_on_failure?
      true
    end

    private

    def config
      Rodiff.configuration
    end

    def args_presence(*args)
      args.each_with_object([true, true]) do |e, acc|
        acc[0] = false if e.nil? || e == ""
        acc[1] = false unless e.nil? || e == ""
      end
    end

    def odiff_exec(*cmd)
      parts = []
      parts << config.odiff_exe_path
      parts.push(*cmd)

      stdout, stderr, status = Open3.capture3(parts.join(" "))
      if block_given?
        yield stdout, stderr, status
      else
        say_error stderr unless stderr.nil? || stderr == ""
        say stdout unless stdout.nil? || stdout == ""
      end
    end
  end
end
