# frozen_string_literal: true

require "dry/cli"

module Rodiff
  module Command
    class Version < Dry::CLI::Command
      desc "Print version"

      def call(*)
        require "rodiff/version"
        puts Rodiff::VERSION
      end
    end
  end
end
