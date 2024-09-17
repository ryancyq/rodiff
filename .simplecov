# frozen_string_literal: true

SimpleCov.start do
  enable_coverage :branch

  if ENV["CI"]
    coverage_dir File.join(ENV.fetch("COV_DIR", "."), "coverage-ruby-#{RUBY_VERSION}")
    require "simplecov-cobertura"
    SimpleCov::Formatter::CoberturaFormatter
  end
end
