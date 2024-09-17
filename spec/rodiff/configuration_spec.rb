# frozen_string_literal: true

require "spec_helper"
require "rodiff/configuration"

RSpec.describe Rodiff::Configuration do
  let(:config) { described_class.new }

  describe "READER_ATTRS" do
    described_class::READER_ATTRS.each do |key, value|
      context "with ##{key}" do
        it "reads" do
          expect(config.public_send(key)).to eq value
        end

        context "when overrides" do
          it "reads overrided value" do
            expect(config.public_send(key)).to eq value
            expect { config.overrides [[key, "overrided-value"]].to_h }.not_to raise_error
            expect(config.public_send(key)).to eq "overrided-value"
          end
        end
      end
    end
  end

  describe "ACCESSOR_ATTRS" do
    described_class::ACCESSOR_ATTRS.each do |key, value|
      context "with ##{key}" do
        it "reads" do
          expect(config.public_send(key)).to eq value
        end

        it "writes" do
          expect(config.public_send(key)).to eq value
          expect { config.public_send("#{key}=", "random-value") }.not_to raise_error
          expect(config.public_send(key)).to eq "random-value"
        end

        context "when overrides" do
          it "reads overrided value" do
            expect(config.public_send(key)).to eq value
            expect { config.overrides [[key, "overrided-value"]].to_h }.not_to raise_error
            expect(config.public_send(key)).to eq "overrided-value"
          end
        end
      end
    end
  end

  describe "unknown configuration" do
    context "when reading" do
      it "raises #{NoMethodError}" do
        expect { config.abc }.to raise_error(
          NoMethodError,
          "undefined method `abc' for an instance of Rodiff::Configuration"
        )
      end
    end

    context "when writing" do
      it "raises #{NoMethodError}" do
        expect { config.abc = "1" }.to raise_error(
          NoMethodError,
          "undefined method `abc=' for an instance of Rodiff::Configuration"
        )
      end
    end

    context "when overriding" do
      it "raises #{described_class::UnknownConfiguration}" do
        expect { config.overrides(abc: "1") }.to raise_error(
          described_class::UnknownConfiguration,
          "unknown config :abc"
        )
      end
    end
  end
end
