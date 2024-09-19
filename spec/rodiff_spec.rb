# frozen_string_literal: true

require "spec_helper"

require "rodiff"

RSpec.describe Rodiff do
  let(:stub_config) { instance_double(Rodiff::Configuration) }

  %w[Configuration Executable].each do |mod|
    it "loads #{mod}" do
      expect(described_class).to be_const_defined(mod)
    end
  end

  it "has configuration" do
    expect(described_class.configuration).to be_a(Rodiff::Configuration)
  end

  it "can be configured" do
    allow(stub_config).to receive(:exit_code_error=)
    allow(described_class).to receive(:configuration).and_return(stub_config)

    expect do
      described_class.configure do |config|
        config.exit_code_error = "1"
      end
    end.not_to raise_error
    expect(stub_config).to have_received(:exit_code_error=).with("1")
  end
end
