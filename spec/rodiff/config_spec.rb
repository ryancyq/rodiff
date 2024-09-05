# frozen_string_literal: true

require "spec_helper"
require "rbconfig"
require "rodiff/config"

RSpec.describe Rodiff::Config do
  describe "#host_os" do
    it "returns the host operating system" do
      expect(described_class.host_os).to eq(RbConfig::CONFIG["host_os"])
    end
  end

  describe "#host_arch" do
    it "returns the host architecture" do
      expect(described_class.host_arch).to eq(RbConfig::CONFIG["arch"])
    end
  end

  describe "#executable_dir" do
    context "when on Linux or macOS" do
      it "returns /usr/local/bin" do
        allow(described_class).to receive(:host_os).and_return("linux")
        expect(described_class.executable_dir).to eq("/usr/local/bin")
      end
    end

    context "when on Windows" do
      it "returns the AppData local odiff directory path" do
        allow(described_class).to receive(:host_os).and_return("mswin")
        expected_path = File.join(Dir.home, "AppData", "Local", "odiff")
        expect(described_class.executable_dir).to eq(expected_path)
      end
    end

    context "when on an unsupported OS" do
      it "raises an error" do
        allow(described_class).to receive(:host_os).and_return("unsupported_os")
        expect { described_class.executable_dir }.to raise_error(RuntimeError, %r{Unsupported OS: unsupported_os})
      end
    end
  end

  describe "#executable_name" do
    context "when on Linux or macOS" do
      it "returns odiff" do
        allow(described_class).to receive(:host_os).and_return("linux")
        expect(described_class.executable_name).to eq("odiff")
      end
    end

    context "when on Windows" do
      it "returns odiff.exe" do
        allow(described_class).to receive(:host_os).and_return("mswin")
        expect(described_class.executable_name).to eq("odiff.exe")
      end
    end

    context "when on an unsupported OS" do
      it "raises an error" do
        allow(described_class).to receive(:host_os).and_return("unsupported_os")
        expect { described_class.executable_name }.to raise_error(RuntimeError, %r{Unsupported OS: unsupported_os})
      end
    end
  end

  describe "#executable_path" do
    it "joins executable_dir and executable_name to form the full path" do
      allow(described_class).to receive_messages(executable_dir: "/some/path", executable_name: "odiff")
      expect(described_class.executable_path).to eq("/some/path/odiff")
    end
  end

  describe "#configure" do
    it "allows configuration through a block" do
      described_class.configure do |config|
        config.executable_dir = "/custom/path"
        config.executable_name = "custom_odiff"
      end

      expect(described_class.executable_dir).to eq("/custom/path")
      expect(described_class.executable_name).to eq("custom_odiff")
    end
  end
end
