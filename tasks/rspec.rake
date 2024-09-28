# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec, [:coverage]) do |config, args|
  config.ruby_opts = "-r./.simplecov_spawn" if args[:coverage]
  config.rspec_opts = "--format documentation"
end
