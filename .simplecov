# frozen_string_literal: true

SimpleCov.start do
  enable_coverage :branch
  command_name "ruby-#{RUBY_VERSION}"
  coverage_dir File.join(ENV.fetch("COV_DIR", "coverage"), command_name)

  if ENV["CI"]
    require "simplecov-cobertura"
    formatter SimpleCov::Formatter::CoberturaFormatter
  end
end
