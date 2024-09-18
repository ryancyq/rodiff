# frozen_string_literal: true

require "spec_helper"

require "rodiff/command/version"

RSpec.describe Rodiff::Command::Version do
  let(:args) { [] }
  let(:command) { described_class.new.call(*args) }

  it "prints" do
    expect { command }.to output("1.0.0\n").to_stdout
  end
end
