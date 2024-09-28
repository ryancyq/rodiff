# frozen_string_literal: true

SimpleCov.configure do
  enable_coverage :branch
  command_name "ruby-#{RUBY_VERSION}"
  coverage_dir File.join(ENV.fetch("COV_DIR", "coverage"), command_name)

  at_fork do |pid|
    command_name "#{command_name} (subprocess: #{pid})"
  end

  if ENV["CI"]
    require "simplecov-cobertura"
    formatter SimpleCov::Formatter::CoberturaFormatter
  end
end
