# frozen_string_literal: true

module Rodiff
  def self.configuration
    @configuration ||= Rodiff::Configuration.new
  end

  def self.configure
    yield configuration
  end

  class Configuration
    class UnknownConfiguration < StandardError; end

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

    def self.config_attribute_template(name, type:)
      case type
      when :reader then "attr_reader :#{name}"
      when :writer then "attr_writer :#{name}"
      when :accessor then "attr_accessor :#{name}"
      when :attr_proxy
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
      *READER_ATTRS.keys.map { |key| config_attribute_template(key, type: :reader) },
      *ACCESSOR_ATTRS.keys.map { |key| config_attribute_template(key, type: :accessor) }
    ]

    generate_config self, __FILE__, __LINE__, [
      *READER_ATTRS.keys.map { |key| config_attribute_template(key, type: :attr_proxy) },
      *ACCESSOR_ATTRS.keys.map { |key| config_attribute_template(key, type: :attr_proxy) }
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
  end
end
