# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

require "rodiff/executable"

RSpec.describe Rodiff::Executable do
  describe "#platform" do
    let(:platform) { described_class.platform }

    machine = "#{Gem::Platform.local.cpu}-#{Gem::Platform.local.os}"
    it "is #{machine} without version" do
      expect(platform).to eq machine
    end
  end

  describe "#resolve" do
    let(:exe_filename) { "odiff" }
    let(:tmp_exe_dir) do
      lambda do |platform, &block|
        Dir.mktmpdir do |dir|
          stub_const("Rodiff::Executable::DEFAULT_DIR", dir)
          FileUtils.mkdir(File.join(dir, platform))
          exe_path = File.join(dir, platform, exe_filename)
          FileUtils.touch(exe_path)
          block.call(dir, exe_path)
        end
      end
    end

    let(:local_odiff_dir) do
      lambda do |&block|
        Dir.mktmpdir do |dir|
          exe_path = File.join(dir, exe_filename)
          FileUtils.touch(exe_path)
          block.call(dir, exe_path)
        end
      end
    end

    it "returns the default exe path" do
      tmp_exe_dir.call(described_class.platform) do |dir, exe|
        expect(File.expand_path(File.join(dir, described_class.platform, "odiff"))).to eq exe
        expect(described_class.resolve).to eq exe
      end
    end

    it "returns the absolute path to the binary" do
      allow(Gem::Platform).to receive(:match_gem?).and_return(true)
      tmp_exe_dir.call("my-os-platform") do |dir, exe|
        expect(File.expand_path(File.join(dir, "my-os-platform", "odiff"))).to eq exe
        expect(described_class.resolve(exe_path: dir)).to eq exe
      end
    end

    it "raises UnsupportedPlatform for unsupported platform" do
      allow(Gem::Platform).to receive(:match_gem?).and_return(false)
      expect { described_class.resolve }.to raise_error(
        described_class::UnsupportedPlatform,
        %r{odiff does not support the .+? platform}
      )
    end

    it "raises ExecutableNotFound when the executable not found" do
      Dir.mktmpdir do |dir| # empty directory
        expect { described_class.resolve(exe_path: dir) }.to raise_error(
          described_class::ExecutableNotFound,
          %r{Cannot find the odiff executable for .+? in}
        )
      end
    end

    it "returns the executable in ODIFF_INSTALL_DIR when no packaged binary exists" do
      local_odiff_dir.call do |install_dir, exe|
        allow(described_class).to receive(:warn)
        allow(ENV).to receive(:fetch).and_return(install_dir)

        expect(described_class.resolve(exe_path: "/does/not/exist")).to eq exe
        expect(described_class).to have_received(:warn).with(
          %r{NOTE: using ODIFF_INSTALL_DIR to find odiff executable:}
        )
        expect(ENV).to have_received(:fetch).with("ODIFF_INSTALL_DIR", nil)
      end
    end

    it "returns the executable in ODIFF_INSTALL_DIR for unsupported platform" do
      allow(Gem::Platform).to receive(:match_gem?).and_return(false)
      local_odiff_dir.call do |install_dir, exe|
        allow(described_class).to receive(:warn)
        allow(ENV).to receive(:fetch).and_return(install_dir)

        expect(described_class.resolve).to eq exe
        expect(described_class).to have_received(:warn).with(
          %r{NOTE: using ODIFF_INSTALL_DIR to find odiff executable:}
        )
        expect(ENV).to have_received(:fetch).with("ODIFF_INSTALL_DIR", nil)
      end
    end

    it "returns the executable in ODIFF_INSTALL_DIR even when a packaged binary exists" do
      tmp_exe_dir.call("my-os-platform") do |dir, _exe|
        local_odiff_dir.call do |install_dir, exe|
          allow(described_class).to receive(:warn)
          allow(ENV).to receive(:fetch).and_return(install_dir)

          expect(described_class.resolve(exe_path: dir)).to eq exe
          expect(described_class).to have_received(:warn).with(
            %r{NOTE: using ODIFF_INSTALL_DIR to find odiff executable:}
          )
          expect(ENV).to have_received(:fetch).with("ODIFF_INSTALL_DIR", nil)
        end
      end
    end

    it "raises ExecutableNotFound if ODIFF_INSTALL_DIR is set to a nonexistent dir" do
      allow(ENV).to receive(:fetch).and_return("/does/not/exist")
      expect { described_class.resolve }.to raise_error(
        described_class::InstallDirectoryNotFound,
        "ODIFF_INSTALL_DIR is set to /does/not/exist, but that directory does not exist."
      )
    end

    context "with odiff.exe filename" do
      let(:exe_filename) { "odiff.exe" }

      it "returns the executable in ODIFF_INSTALL_DIR" do
        local_odiff_dir.call do |install_dir, exe|
          allow(described_class).to receive(:warn)
          allow(ENV).to receive(:fetch).and_return(install_dir)

          expect(described_class.resolve).to eq exe
          expect(described_class).to have_received(:warn).with(
            %r{NOTE: using ODIFF_INSTALL_DIR to find odiff executable:}
          )
          expect(ENV).to have_received(:fetch).with("ODIFF_INSTALL_DIR", nil)
        end
      end
    end
  end
end
