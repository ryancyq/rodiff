# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec, [:coverage]) do |config, args|
  opts = []
  opts << "--format documentation"
  opts << "--require 'simplecov'" if args[:coverage]
  config.rspec_opts = opts.join(" ")
end
