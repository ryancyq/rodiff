# frozen_string_literal: true

module Rodiff
  VERSION = "0.1.0"
  ODIFF_VERSION = "3.X"

  def self.compatible_odiff_version(version)
    Gem::Version.new(Rodiff::ODIFF_VERSION).segments.first == Gem::Version.new(version).segments.first
  end
end
