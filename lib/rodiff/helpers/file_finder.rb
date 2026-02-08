# frozen_string_literal: true

module Rodiff
  module Helpers
    class FileFinder
      attr_reader :root_dir

      def initialize(root)
        @root_dir = root
      end

      def find_upwards(filename, start_dir, stop_dir = nil)
        traverse_upwards(filename, start_dir, stop_dir) { |file| return file if file } # return first result
      end

      def find_top_most(filename, start_dir, stop_dir = nil)
        top_most_file = nil
        traverse_upwards(filename, start_dir, stop_dir) { |file| top_most_file = file }
        top_most_file
      end

      private

      def traverse_upwards(filename, start_dir, stop_dir)
        start = Pathname.new(start_dir).expand_path
        root = Pathname.new(root_dir).expand_path
        return unless start.to_s.start_with?(root.to_s)

        stop = Pathname.new(stop_dir).expand_path if stop_dir
        start.ascend do |dir|
          file = File.join(dir, filename)
          yield(file) if File.exist?(file)

          break if dir == stop || dir == root
        end
      end
    end
  end
end
