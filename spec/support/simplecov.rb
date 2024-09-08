# frozen_string_literal: true

if ENV["CODE_COV"]
  require "simplecov"
  SimpleCov.start
end

if ENV["CODE_COV"] && ENV["CI"]
  require "simplecov-cobertura"
  SimpleCov.formatter = SimpleCov::Formatter::CoberturaFormatter
end
