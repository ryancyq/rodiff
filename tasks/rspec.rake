# frozen_string_literal: true

require "rspec/core/rake_task"

RSpec::Core::RakeTask.new(:spec) do |config|
  config.rspec_opts = "--format documentation"
end
