# frozen_string_literal: true

require "spec_helper"
require "tmpdir"

require "rodiff/helpers/file_finder"

RSpec.describe Rodiff::Helpers::FileFinder do
  let(:nested_dir) do
    lambda do |level, &block|
      Dir.mktmpdir do |root|
        dirs = []
        level.times.each do |i|
          dirs.unshift Pathname.new(dirs.first || root).join("parent #{i + 1}")
          FileUtils.mkdir(dirs.first)
        end

        block.call(root, dirs)
      end
    end
  end

  describe "#root_dir" do
    let(:root) { "/" }
    let(:finder) { described_class.new(root) }

    it "initializes" do
      expect(finder.root_dir).to eq "/"
    end
  end

  describe "#find_upwards" do
    context "when file does not exist" do
      it "returns nil" do
        nested_dir.call(3) do |root, dirs|
          finder = described_class.new(root)
          expect(finder.find_upwards("test.txt", dirs[0])).to be_nil
        end
      end
    end

    context "when file exists" do
      it "finds" do
        nested_dir.call(3) do |root, dirs|
          finder = described_class.new(root)

          file = File.join(dirs[0], "test.txt")
          FileUtils.touch(file)

          expect(finder.find_upwards("test.txt", dirs[0])).to eq("#{root}/parent 1/parent 2/parent 3/test.txt")
        end
      end
    end

    context "when file exists in non-inclusive parents" do
      it "returns nil" do
        nested_dir.call(5) do |root, dirs|
          finder = described_class.new(root)

          file = File.join(dirs[-2], "test.txt")
          FileUtils.touch(file)

          expect(finder.find_upwards("test.txt", dirs[0], dirs[1])).to be_nil
          expect(finder.find_upwards("test.txt", dirs[0], root)).to eq("#{root}/parent 1/parent 2/test.txt")
        end
      end
    end

    context "when file exists at root" do
      it "finds" do
        nested_dir.call(3) do |root, dirs|
          finder = described_class.new(root)

          file = File.join(root, "test.txt")
          FileUtils.touch(file)

          expect(finder.find_upwards("test.txt", dirs[0], dirs[-2])).to be_nil
          expect(finder.find_upwards("test.txt", dirs[0], root)).to eq("#{root}/test.txt")
        end
      end
    end

    context "when file exists outside of root" do
      it "returns nil" do
        nested_dir.call(0) do |root, _|
          finder = described_class.new(root)

          Dir.mktmpdir do |another_root|
            file = File.join(another_root, "test.txt")
            FileUtils.touch(file)
            expect(finder.find_upwards("test.txt", another_root)).to be_nil
          end
        end
      end
    end
  end

  describe "#find_top_most" do
    context "when file does not exist" do
      it "returns nil" do
        nested_dir.call(3) do |root, dirs|
          finder = described_class.new(root)
          expect(finder.find_top_most("test.txt", dirs[0])).to be_nil
        end
      end
    end

    context "when single file exists" do
      it "finds" do
        nested_dir.call(3) do |root, dirs|
          finder = described_class.new(root)

          file = File.join(dirs[1], "test.txt")
          FileUtils.touch(file)

          expect(finder.find_top_most("test.txt", dirs[0], root)).to eq("#{root}/parent 1/parent 2/test.txt")
        end
      end
    end

    context "when multiple files exist" do
      it "finds" do
        nested_dir.call(3) do |root, dirs|
          finder = described_class.new(root)

          dirs.each do |dir|
            file = File.join(dir, "test.txt")
            FileUtils.touch(file)
          end

          expect(finder.find_top_most("test.txt", dirs[0], root)).to eq("#{root}/parent 1/test.txt")
        end
      end

      it "finds file at root" do
        nested_dir.call(3) do |root, dirs|
          finder = described_class.new(root)

          file = File.join(root, "test.txt")
          FileUtils.touch(file)

          dirs.each do |dir|
            file = File.join(dir, "test.txt")
            FileUtils.touch(file)
          end

          expect(finder.find_top_most("test.txt", dirs[0], root)).to eq("#{root}/test.txt")
        end
      end
    end
  end
end
