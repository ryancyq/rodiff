# frozen_string_literal: true

require "tmpdir"
require "spec_helper"
require_relative "../../ext/rodiff/github"

RSpec.describe Rodiff::Github do
  let(:github) { described_class.new }

  before do
    allow(Rodiff::Config).to receive_messages({
      host_os:         "linux",
      host_arch:       "x86_64",
      executable_dir:  "/path/to/dir",
      executable_name: "my-executable"
    })
  end

  describe "#download" do
    let(:bin_dir) { "/test/bin" }
    let(:bin_name) { "my_executable" }

    it "fetch metadata, downloads binary", vcr: "github-release-binary-download-success" do
      Dir.mktmpdir(bin_dir) do |dir|
        allow(Rodiff::Config).to receive_messages({
          executable_dir:  dir,
          executable_name: bin_name
        })
        github.download

        expect(File).to exist(Rodiff::Config.executable_path)
        expect(File.stat(Rodiff::Config.executable_path).mode.to_s(8)).to eq "100755"
      end
    end
  end

  describe "#fetch_metadata" do
    it "fetches and parses metadata successfully", vcr: "github-release-api-success" do
      expect(github.fetch_metadata).to be_an(Array)
    end

    it "raises an error if metadata fetching fails" do
      uri_double = instance_double(URI::HTTP)
      allow(uri_double).to receive(:open).and_raise(StandardError, "network timeout")
      allow(URI).to receive(:parse).and_return(uri_double)

      expect { github.fetch_metadata }.to raise_error(
        SystemExit, "Failed to fetch the releases info: network timeout"
      )
      expect(URI).to have_received(:parse)
      expect(uri_double).to have_received(:open)
    end
  end

  describe "#find_compatible_binaries" do
    it "finds compatible binaries", vcr: "github-release-api-success" do
      expect do
        github.fetch_metadata
        github.find_compatible_binaries
      end.not_to raise_error

      expect(github.metadata).not_to be_empty
      expect(github.binaries).not_to be_empty
    end

    it "aborts if no binaries are found" do
      allow(github).to receive(:platform_binary_name).and_return("nonexistent-binary")
      expect { github.find_compatible_binaries }.to raise_error(
        SystemExit,
        "No binary (nonexistent-binary) found for linux(x86_64)"
      )
      expect(github).to have_received(:platform_binary_name)
    end
  end

  describe "#download_binary" do
    let(:version) { "3.1.1" }
    let(:url) { "https://github.com/dmtrKovalenko/odiff/releases/download/v3.1.1/odiff-macos-arm64.exe" }

    before do
      allow(github).to receive(:binaries).and_return([{ version: version, url: url }])
      allow(FileUtils).to receive(:mkdir_p)
      allow(File).to receive(:binwrite)
    end

    after do
      # VCR gem rely on these methods to write http interactions,
      # so restore them after we are done with the assetions
      allow(FileUtils).to receive(:mkdir_p).and_call_original
      allow(File).to receive(:binwrite).and_call_original
    end

    it "downloads the binary successfully", vcr: "github-download-api-success" do
      allow(github).to receive(:chmod_executable)

      expect { github.download_binary }.not_to raise_error
      expect(github).to have_received(:binaries)
      expect(FileUtils).to have_received(:mkdir_p)
      expect(File).to have_received(:binwrite)
      expect(github).to have_received(:chmod_executable)
    end

    it "raises an error if downloading the binary fails" do
      allow(URI).to receive(:parse).and_raise(StandardError, "network reset")
      expect { github.download_binary }.to raise_error(
        SystemExit,
        "Failed to download binary: network reset"
      )
      expect(URI).to have_received(:parse)
    end
  end

  describe "#platform_binary_name" do
    it "returns the correct binary name for Linux" do
      expect(github.platform_binary_name).to eq("odiff-linux-x64.exe")
    end

    it "returns the correct binary name for macOS x86_64" do
      allow(Rodiff::Config).to receive(:host_os).and_return("darwin")
      expect(github.platform_binary_name).to eq("odiff-macos-x64.exe")
    end

    it "returns the correct binary name for macOS arm64" do
      allow(Rodiff::Config).to receive_messages(host_os: "darwin", host_arch: "arm64")
      expect(github.platform_binary_name).to eq("odiff-macos-arm64.exe")
    end

    it "returns the correct binary name for windows" do
      allow(Rodiff::Config).to receive(:host_os).and_return("mswin")
      expect(github.platform_binary_name).to eq("odiff-windows-x64.exe")
    end
  end
end
