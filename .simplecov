# frozen_string_literal: true

SimpleCov.start do
  enable_coverage :branch

  if ENV["CI"]
    coverage_dir "coverage-ruby-#{RUBY_VERSION}"
    require "simplecov-cobertura"
    SimpleCov::Formatter::CoberturaFormatter
  end
end
