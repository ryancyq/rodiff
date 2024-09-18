# frozen_string_literal: true

require "dry/cli"
require "rodiff/command/version"

module Rodiff
  module CLI
    module Commands
      extend Dry::CLI::Registry

      register "version", Rodiff::Command::Version, aliases: ["-v", "--version"]
    end
  end
end
