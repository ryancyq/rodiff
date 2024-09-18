# frozen_string_literal: true

require "spec_helper"

require "rodiff/cli/commands"
require "rodiff/command/version"

RSpec.describe Rodiff::CLI::Commands do
  let(:command_lookup) { described_class.get(command_names) }

  context "with version command" do
    context "when 'version'" do
      let(:command_names) { ["version"] }

      it "finds" do
        expect(command_lookup).to be_found
        expect(command_lookup.command).to eq Rodiff::Command::Version
      end
    end

    context "when 'v'" do
      let(:command_names) { ["v"] }

      it "does not find" do
        expect(command_lookup).not_to be_found
      end
    end

    context "when '-v'" do
      let(:command_names) { ["-v"] }

      it "finds" do
        expect(command_lookup).to be_found
        expect(command_lookup.command).to eq Rodiff::Command::Version
      end
    end

    context "when '--v'" do
      let(:command_names) { ["--v"] }

      it "does not find" do
        expect(command_lookup).not_to be_found
      end
    end

    context "when '--version'" do
      let(:command_names) { ["--version"] }

      it "finds" do
        expect(command_lookup).to be_found
        expect(command_lookup.command).to eq Rodiff::Command::Version
      end
    end
  end

  context "with unknown command" do
    let(:command_names) { ["unknown"] }

    it "does not find" do
      expect(command_lookup).not_to be_found
    end
  end
end
