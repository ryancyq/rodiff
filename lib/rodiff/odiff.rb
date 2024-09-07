# frozen_string_literal: true

module Rodiff
  module Odiff
    VERSION = "v3.1.1"

    # rubygems platform name => upstream release filename
    NATIVE_PLATFORMS = {
      "arm64-darwin"   => "odiff-macos-arm64.exe",
      "x64-mingw32"    => "odiff-windows-x64.exe",
      "x64-mingw-ucrt" => "odiff-windows-x64.exe",
      "x86_64-darwin"  => "odiff-macos-x64.exe",
      "x86_64-linux"   => "odiff-linux-x64.exe"
    }.freeze
  end
end
