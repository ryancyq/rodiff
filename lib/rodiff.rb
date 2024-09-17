# frozen_string_literal: true

require_relative "rodiff/configuration"

module Rodiff
  class << self
    def configuration
      @configuration ||= Rodiff::Configuration.new
    end

    def configure
      yield configuration
    end
  end
end
