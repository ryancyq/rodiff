# frozen_string_literal: true

require "rodiff/error"
require "rodiff/executable"

module Rodiff
  def self.configuration
    @configuration ||= Rodiff::Configuration.new
  end

  def self.configure
    yield configuration
  end

  class Configuration
    class UnknownConfiguration < Rodiff::Error; end

    DOTFILE = ".rodiff.yml"
    ROOT = if RUBY_VERSION >= "3.1"
             File.dirname(__FILE__, 3).freeze
           else
             File.expand_path(File.join(File.dirname(__FILE__), "..", "..")).freeze
           end
    DEFAULT_CONFIG = File.join(ROOT, "config", "default.yml").freeze

    ATTRS = Module.new.tap { |mod| include mod }
    READER_ATTRS = {
      default_dir: "/"
    }.freeze

    ACCESSOR_ATTRS = {
      include_pattern:       "{*,**/*}.jpg",
      exclude_pattern:       "",
      compare_pattern:       "",

      ignore_antialiasing:   false,
      color_threshold:       0.1,
      output_diff_mask:      false,

      exit_code_odiff:       ->(code) { code },
      exit_code_error:       1,
      fail_if_no_comparison: false
    }.freeze

    def self.generate_config(mod, path, line, attrs)
      mod.module_eval(Array(attrs).join(";").to_s, path, line)
    end

    def self.config_attribute(name, type:)
      case type
      when :reader, :writer, :accessor then "attr_#{type} :#{name}"
      when :proxy
        <<-RUBY
          def #{name}
            value_for(:#{name}) { super() }
          end
        RUBY
      else
        raise ArgumentError, "unsupported type #{type.inspect}"
      end
    end

    generate_config ATTRS, __FILE__, __LINE__, [
      *READER_ATTRS.keys.map { |key| config_attribute(key, type: :reader) },
      *ACCESSOR_ATTRS.keys.map { |key| config_attribute(key, type: :accessor) }
    ]

    generate_config self, __FILE__, __LINE__, [
      *READER_ATTRS.keys.map { |key| config_attribute(key, type: :proxy) },
      *ACCESSOR_ATTRS.keys.map { |key| config_attribute(key, type: :proxy) }
    ]

    def initialize
      @config_overrides = {}

      READER_ATTRS.each { |key, value| instance_variable_set("@#{key}", value) }
      ACCESSOR_ATTRS.each { |key, value| instance_variable_set("@#{key}", value) }
    end

    def odiff_exe_path
      @odiff_exe_path ||= Rodiff::Executable.resolve
    end

    def odiff_exe_path=(path)
      @odiff_exe_path = Rodiff::Executable.resolve(exe_path: path)
    end

    def overrides(opts = {})
      opts.each_key { |key| validate_config_key!(key) }
      @config_overrides.merge!(opts.transform_keys(&:to_sym))
    end

    private

    def validate_config_key!(key)
      return if READER_ATTRS.key?(key) || ACCESSOR_ATTRS.key?(key)

      raise UnknownConfiguration, "unknown config #{key.inspect}"
    end

    def value_for(key, &block)
      validate_config_key!(key)
      @config_overrides.fetch(key, &block)
    end

    def files_from_dir(dir)
      included_files = files_from_glob(file_glob(dir, include_pattern))
      excluded_files = files_from_glob(file_glob(dir, exclude_pattern))
      (included_files - excluded_files).uniq
    end

    def files_from_glob(file_glob)
      files = Dir.glob(file_glob)
      files.map { |file| File.expand_path(file) }.sort
    end

    def file_glob_pattern(path, pattern)
      trimmed = "{#{pattern.gsub(%r{\s*,\s*}, ",")}}"
      return trimmed if pattern =~ %r{^(\./)?#{Regexp.escape(path)}} || absolute_pattern?(pattern)

      File.join(path, trimmed)
    end

    def absolute_pattern?(pattern)
      return pattern.start_with?(File::Separator) unless windows?
      return false unless File::ALT_SEPARATOR

      win_absolute_pattern = %r{\A\w+:#{Regexp.escape(File::ALT_SEPARATOR)}}.test(pattern)
      win_network_pattern = pattern.start_with?(File::ALT_SEPARATOR * 2)
      win_absolute_pattern || win_network_pattern
    end

    def windows?
      @windows ||= begin
        require "rbconfig"
        os = RbConfig::CONFIG["host_os"]
        os.match?(%r{mingw})
      end
    end
  end
end
