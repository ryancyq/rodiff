# frozen_string_literal: true

require "yaml"
require "rodiff/error"
require "rodiff/executable"
require "rodiff/helpers/file_finder"

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
    GEM_ROOT = if RUBY_VERSION >= "3.1"
                 File.dirname(__FILE__, 3).freeze
               else
                 File.expand_path(File.join(File.dirname(__FILE__), "..", "..")).freeze
               end
    DEFAULT_CONFIG = File.join(GEM_ROOT, "config", "default.yml").freeze
    SEARCH_ROOT = Dir.home.freeze

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

      load_from_file(DEFAULT_CONFIG)
      load_from_file(config_file_override) if config_file_override
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

    def config_file_override(start_dir: Dir.pwd)
      @config_file_override ||= begin
        finder = Helpers::FileFinder.new("/")
        finder.find_upwards(DOTFILE, start_dir, SEARCH_ROOT)
      end
    end

    def load_from_file(path)
      yml_config = YAML.load_file(path) if File.exist?(path)

      if yml_config.is_a?(Hash)
        yml_config.each do |key, value|
          validate_config_key!(key.to_sym)
          public_send("#{key}=", value) if respond_to?("#{key}=")
        end
      elsif empty_yml?(yml_config)
        warn "Configuration file #{path} is empty"
      else
        warn "Configuration file #{path} must contain a Hash, got #{yml_config.class}"
      end
    rescue Psych::SyntaxError => e
      raise Rodiff::Error, "Invalid YAML in #{path}: #{e.message}"
    end

    def empty_yml?(data)
      # Ruby 2.7-3.0 with Psych 3.x
      return data == false if RUBY_VERSION < "3.1"

      # Ruby 3.1+ with Psych 4.x
      data.nil?
    end

    def validate_config_key!(key)
      return if READER_ATTRS.key?(key) || ACCESSOR_ATTRS.key?(key)

      raise UnknownConfiguration, "unknown config #{key.inspect}"
    end

    def value_for(key, &block)
      validate_config_key!(key)
      @config_overrides.fetch(key, &block)
    end

    def files_from_dir(dir)
      included_files = files_from_glob(file_glob_pattern(dir, include_pattern))
      excluded_files = files_from_glob(file_glob_pattern(dir, exclude_pattern))
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

      win_absolute_pattern = %r{\A\w+:#{Regexp.escape(File::ALT_SEPARATOR)}}.match?(pattern)
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
