# frozen_string_literal: true

require "spec_helper"
require "tmpdir"
require "fileutils"

require "rodiff/configuration"

RSpec.describe Rodiff::Configuration do
  let(:config) do
    # Create config without auto-discovery for isolated testing
    instance = described_class.allocate
    instance.instance_variable_set(:@config_overrides, {})
    described_class::READER_ATTRS.each { |key, value| instance.instance_variable_set("@#{key}", value) }
    described_class::ACCESSOR_ATTRS.each { |key, value| instance.instance_variable_set("@#{key}", value) }
    instance
  end

  describe "#odiff_exe_path" do
    it "resolves to default path" do
      allow(Rodiff::Executable).to receive(:resolve).and_return("default_exe_path")
      expect(config.odiff_exe_path).to eq("default_exe_path")
      expect(Rodiff::Executable).to have_received(:resolve)
    end

    it "can be configured" do
      allow(Rodiff::Executable).to receive(:resolve)
      expect { config.odiff_exe_path = "my_exe_path" }.not_to raise_error
      expect(Rodiff::Executable).to have_received(:resolve).with(exe_path: "my_exe_path")
    end
  end

  describe "DOTFILE" do
    subject { described_class::DOTFILE }

    it { is_expected.to eq ".rodiff.yml" }
  end

  describe "GEM_ROOT" do
    subject { described_class::GEM_ROOT }

    it { is_expected.to eq Pathname.new(__dir__).dirname.parent.to_s }
  end

  describe "DEFAULT_CONFIG" do
    subject { described_class::DEFAULT_CONFIG }

    it { is_expected.to end_with("/config/default.yml") }
  end

  describe "SEARCH_ROOT" do
    subject { described_class::SEARCH_ROOT }

    it { is_expected.to eq Dir.home }
  end

  describe "read-only attributes" do
    described_class::READER_ATTRS.each do |key, value|
      describe "##{key}" do
        it "has default value" do
          expect(config.public_send(key)).to eq value
        end

        it "can be overridden" do
          expect(config.public_send(key)).to eq value
          expect { config.overrides [[key, "overridden-value"]].to_h }.not_to raise_error
          expect(config.public_send(key)).to eq "overridden-value"
        end
      end
    end
  end

  describe "configurable attributes" do
    described_class::ACCESSOR_ATTRS.each do |key, value|
      describe "##{key}" do
        it "has default value" do
          expect(config.public_send(key)).to eq value
        end

        it "can be set directly" do
          expect(config.public_send(key)).to eq value
          expect { config.public_send("#{key}=", "new-value") }.not_to raise_error
          expect(config.public_send(key)).to eq "new-value"
        end

        it "can be overridden" do
          expect(config.public_send(key)).to eq value
          expect { config.overrides [[key, "overridden-value"]].to_h }.not_to raise_error
          expect(config.public_send(key)).to eq "overridden-value"
        end
      end
    end
  end

  describe "#files_from_glob" do
    it "returns files matching glob pattern" do
      Dir.mktmpdir do |dir|
        FileUtils.touch(File.join(dir, "test1.jpg"))
        FileUtils.touch(File.join(dir, "test2.jpg"))
        FileUtils.touch(File.join(dir, "test3.png"))

        pattern = File.join(dir, "*.jpg")
        files = config.send(:files_from_glob, pattern)

        expect(files.length).to eq(2)
        expect(files.all? { |f| f.end_with?(".jpg") }).to be true
      end
    end
  end

  describe "#files_from_dir" do
    it "returns files matching include pattern" do
      Dir.mktmpdir do |dir|
        FileUtils.touch(File.join(dir, "test1.jpg"))
        FileUtils.touch(File.join(dir, "test2.jpg"))
        FileUtils.touch(File.join(dir, "test3.png"))

        config.include_pattern = "*.jpg"
        files = config.send(:files_from_dir, dir)

        expect(files.length).to eq(2)
        expect(files.all? { |f| f.end_with?(".jpg") }).to be true
      end
    end

    it "excludes files matching exclude pattern" do
      Dir.mktmpdir do |dir|
        FileUtils.touch(File.join(dir, "keep1.jpg"))
        FileUtils.touch(File.join(dir, "keep2.jpg"))
        FileUtils.touch(File.join(dir, "ignore.jpg"))

        config.include_pattern = "*.jpg"
        config.exclude_pattern = "ignore.jpg"
        files = config.send(:files_from_dir, dir)

        expect(files.length).to eq(2)
        expect(files.none? { |f| f.end_with?("ignore.jpg") }).to be true
      end
    end
  end

  describe "#file_glob_pattern" do
    it "builds correct glob pattern" do
      pattern = config.send(:file_glob_pattern, "/test/dir", "*.jpg")
      expect(pattern).to eq("/test/dir/{*.jpg}")
    end

    it "handles multiple patterns" do
      pattern = config.send(:file_glob_pattern, "/test/dir", "*.jpg, *.png")
      expect(pattern).to eq("/test/dir/{*.jpg,*.png}")
    end
  end

  describe "#absolute_pattern?" do
    context "when on Unix-like systems" do
      before { allow(config).to receive(:windows?).and_return(false) }

      it "detects absolute paths" do
        expect(config.send(:absolute_pattern?, "/absolute/path")).to be(true)
        expect(config.send(:absolute_pattern?, "relative/path")).to be(false)
      end
    end

    context "when on Windows systems" do
      before do
        allow(config).to receive(:windows?).and_return(true)
        stub_const("File::ALT_SEPARATOR", "\\")
      end

      it "detects Windows absolute paths" do
        expect(config.send(:absolute_pattern?, "C:\\path")).to be(true)
      end

      it "detects Windows network paths" do
        expect(config.send(:absolute_pattern?, "\\\\server\\share")).to be(true)
      end

      it "detects relative paths" do
        expect(config.send(:absolute_pattern?, "relative\\path")).to be(false)
      end

      it "handles missing File::ALT_SEPARATOR" do
        stub_const("File::ALT_SEPARATOR", nil)
        expect(config.send(:absolute_pattern?, "C:\\path")).to be(false)
      end
    end
  end

  describe "configuration file discovery" do
    it "loads .rodiff.yml from current directory" do
      Dir.mktmpdir do |dir|
        config_content = <<~YAML
          include_pattern: "auto/**/*.png"
          color_threshold: 0.9
        YAML

        File.write(File.join(dir, ".rodiff.yml"), config_content)

        Dir.chdir(dir) do
          new_config = described_class.new
          expect(new_config.include_pattern).to eq("auto/**/*.png")
          expect(new_config.color_threshold).to eq(0.9)
        end
      end
    end

    it "loads .rodiff.yml from parent directory" do
      Dir.mktmpdir do |dir|
        config_content = <<~YAML
          include_pattern: "parent/**/*.jpg"
          ignore_antialiasing: true
        YAML

        File.write(File.join(dir, ".rodiff.yml"), config_content)

        subdir = File.join(dir, "subdir")
        FileUtils.mkdir_p(subdir)

        Dir.chdir(subdir) do
          new_config = described_class.new
          expect(new_config.include_pattern).to eq("parent/**/*.jpg")
          expect(new_config.ignore_antialiasing).to be(true)
        end
      end
    end

    it "uses default values when no config file found" do
      Dir.mktmpdir do |dir|
        Dir.chdir(dir) do
          new_config = described_class.new
          expect(new_config.include_pattern).to eq("{*,**/*}.jpg")
          expect(new_config.color_threshold).to eq(0.1)
        end
      end
    end

    it "warns when config file is empty" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, ".rodiff.yml"), "")

        Dir.chdir(dir) do
          expect { described_class.new }.to output(%r{empty}).to_stderr
        end
      end
    end

    it "warns when config file contains non-Hash data" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, ".rodiff.yml"), "- item1\n- item2\n")

        Dir.chdir(dir) do
          expect { described_class.new }.to output(%r{must contain a Hash}).to_stderr
        end
      end
    end

    it "raises error when config file has invalid YAML syntax" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, ".rodiff.yml"), "invalid: yaml: content:\n  - broken")

        Dir.chdir(dir) do
          expect { described_class.new }.to raise_error(Rodiff::Error, %r{Invalid YAML})
        end
      end
    end

    it "raises error when config file contains unknown keys" do
      Dir.mktmpdir do |dir|
        File.write(File.join(dir, ".rodiff.yml"), "unknown_key: value\n")

        Dir.chdir(dir) do
          expect { described_class.new }.to raise_error(
            Rodiff::Configuration::UnknownConfiguration,
            %r{unknown config :unknown_key}
          )
        end
      end
    end
  end

  describe "unknown configuration" do
    context "when reading" do
      it "raises #{NoMethodError}" do
        expect { config.abc }.to raise_error(
          NoMethodError,
          %r{undefined method [`']abc' for (#<|an instance of )Rodiff::Configuration}
        )
      end
    end

    context "when writing" do
      it "raises #{NoMethodError}" do
        expect { config.abc = "1" }.to raise_error(
          NoMethodError,
          %r{undefined method [`']abc=' for (#<|an instance of )Rodiff::Configuration}
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
