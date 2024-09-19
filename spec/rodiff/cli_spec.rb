# frozen_string_literal: true

require "spec_helper"

require "rodiff/cli"

RSpec.describe Rodiff::CLI do
  let(:cli_command) { described_class.start(cmd_parts, shell: stub_shell) }
  let(:exe_path) { "exe_path/odiff" }
  let(:stub_shell) { instance_double(Thor::Shell::Basic) }

  before { allow(Rodiff.configuration).to receive(:odiff_exe_path).and_return(exe_path) }

  describe "#default_command" do
    subject { described_class.default_command }

    let(:stub_cli) { instance_double(described_class) }

    it { is_expected.to eq "compare" }

    it "default to compare command" do
      allow(described_class).to receive(:new).and_return(stub_cli)
      allow(stub_cli).to receive(:args).and_return([])
      allow(stub_cli).to receive(:invoke_command)
      expect do
        described_class.start(
          ["path/to/image"],
          shell:                  stub_shell,
          invoked_via_subcommand: true
        )
      end.not_to raise_error
      expect(described_class).to have_received(:new)
      expect(stub_cli).to have_received(:args)
      expect(stub_cli).to have_received(:invoke_command) do |command|
        expect(command).to be_a(Thor::Command)
        expect(command.name).to eq "compare"
      end
    end
  end

  describe "#version" do
    before { allow(stub_shell).to receive(:say) }

    context "when 'version'" do
      let(:cmd_parts) { ["version"] }

      it "accepts" do
        expect { cli_command }.not_to raise_error
        expect(stub_shell).to have_received(:say).with("1.0.0")
      end
    end

    context "when '-v'" do
      let(:cmd_parts) { ["-v"] }

      it "accepts" do
        expect { cli_command }.not_to raise_error
        expect(stub_shell).to have_received(:say).with("1.0.0")
      end
    end

    context "when '--version'" do
      let(:cmd_parts) { ["--version"] }

      it "accepts" do
        expect { cli_command }.not_to raise_error
        expect(stub_shell).to have_received(:say).with("1.0.0")
      end
    end
  end

  describe "#compare" do
    context "when no args provided" do
      let(:cmd_parts) { ["compare"] }

      it "accepts" do
        allow(Open3).to receive(:capture3)
        expect { cli_command }.not_to raise_error
        expect(Open3).to have_received(:capture3).with(%r{/odiff\s*$})
      end
    end

    context "when partial args provided" do
      let(:cmd_parts) { ["compare", "path/to/baseline", "path/to/variant"] }

      it "rejects" do
        allow(Open3).to receive(:capture3)
        expect { cli_command }.to raise_error(ArgumentError, "BASELINE, VARIANT, DIFF must be provided")
        expect(Open3).not_to have_received(:capture3)
      end
    end

    context "when all args provided" do
      let(:cmd_parts) { ["compare", "path/to/baseline", "path/to/variant", "path/to/diff"] }

      it "accepts" do
        allow(Open3).to receive(:capture3)
        expect { cli_command }.not_to raise_error
        expect(Open3).to have_received(:capture3).with(%r{/odiff path/to/baseline path/to/variant path/to/diff$})
      end
    end
  end
end
