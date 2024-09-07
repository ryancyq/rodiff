# frozen_string_literal: true

require "thor"
require "rodiff/config"

module Rodiff
  class CLI < Thor
    map ["-v", "--version"] => :version

    desc "compare <baseline> <actual>", "Compare actual image against baseline image"
    def compare(baseline, actual); end
  end
end
