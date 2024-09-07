# frozen_string_literal: true

#
#  Rake tasks to manage native gem packages with binary executables from dmtrKovalenko/odiff
#
#  The native platform gems (defined by Rodiff::Odiff::PLATFORMS) will each contain
#  two files in addition to what the vanilla ruby gem contains:
#
#     exe/
#     ├── rodiff                              #  generic ruby script to find and run the binary
#     └── <Gem::Platform architecture name>/
#         └── odiff                           #  the odiff binary executable
#
#  The ruby script `exe/rodiff` is installed into the user's path, and it simply locates the
#  binary and executes it. Note that this script is required because rubygems requires that
#  executables declared in a gemspec must be Ruby scripts.
#
#  Windows support note: we ship the same executable in two gems, the `x64-mingw32` and
#  `x64-mingw-ucrt` flavors because Ruby < 3.1 uses the MSCVRT runtime libraries, and Ruby >= 3.1
#  uses the UCRT runtime libraries. You can read more about this change here:
#
#     https://rubyinstaller.org/2021/12/31/rubyinstaller-3.1.0-1-released.html
#
#  As a concrete example, an x86_64-linux system will see these files on disk after installing
#  rodiff-x.x.x-x86_64-linux.gem:
#
#     exe/
#     ├── rodiff
#     └── x86_64-linux/
#         └── odiff
#
#  So the full set of gem files created will be:
#
#  - pkg/rodiff-1.0.0.gem
#  - pkg/rodiff-1.0.0-arm64-darwin.gem
#  - pkg/rodiff-1.0.0-x64-mingw32.gem
#  - pkg/rodiff-1.0.0-x64-mingw-ucrt.gem
#  - pkg/rodiff-1.0.0-x86_64-darwin.gem
#  - pkg/rodiff-1.0.0-x86_64-linux.gem
#
#  Note that in addition to the native gems, a vanilla "ruby" gem will also be created without
#  either the `exe/rodiff` script or a binary executable present.
#
#  New rake tasks created:
#
#  - rake gem:ruby           # Build the ruby gem
#  - rake gem:arm64-darwin   # Build the arm64-darwin gem
#  - rake gem:x64-mingw32    # Build the x64-mingw32 gem
#  - rake gem:x64-mingw-ucrt # Build the x64-mingw-ucrt gem
#  - rake gem:x86_64-darwin  # Build the x86_64-darwin gem
#  - rake gem:x86_64-linux   # Build the x86_64-linux gem
#  - rake download           # Download all odiff binaries
#
#  Modified rake tasks:
#
#  - rake gem                # Build all the gem files
#  - rake package            # Build all the gem files (same as `gem`)
#  - rake repackage          # Force a rebuild of all the gem files
#
#  Note also that the binary executables will be lazily downloaded when needed, but you can
#  explicitly download them with the `rake download` command.
#

require "rubygems/package_task"
require "open-uri"
require_relative "../lib/rodiff/odiff"

def odiff_download_url(filename)
  [
    "https://github.com/dmtrKovalenko/odiff/releases/download",
    Rodiff::Odiff::VERSION,
    filename
  ].join "/"
end

RODIFF_GEMSPEC = Bundler.load_gemspec("rodiff.gemspec")

# prepend the download task before the Gem::PackageTask tasks
desc "Build all the packages"
task package: :download

gem_path = Gem::PackageTask.new(RODIFF_GEMSPEC).define
desc "Build the ruby gem"
task "gem:ruby" => [gem_path]

exe_paths = []
Rodiff::Odiff::PLATFORMS.each do |platform, filename|
  RODIFF_GEMSPEC.dup.tap do |gemspec|
    exe_dir = File.join(gemspec.bindir, platform) # "exe/x86_64-linux"
    exe_path = File.join(exe_dir, "odiff") # "exe/x86_64-linux/odiff"
    exe_paths << exe_path

    # modify a copy of the gemspec to include the native executable
    gemspec.platform = platform
    gemspec.files += [exe_path, "LICENSE-DEPENDENCIES"]

    # create a package task
    gem_path = Gem::PackageTask.new(gemspec).define
    desc "Build the #{platform} gem"
    task "gem:#{platform}" => [gem_path]

    directory exe_dir
    file exe_path => [exe_dir] do
      release_url = odiff_download_url(filename)
      warn "Downloading #{exe_path} from #{release_url} ..."

      URI.parse(release_url).open do |stream|
        File.binwrite(exe_path, stream.read)
      end
      FileUtils.chmod("u=rwx,go=rx", exe_path, verbose: true)
    end
  end
end

desc "Download all odiff binaries"
task "download" => exe_paths

CLOBBER.add(exe_paths.map { |p| File.dirname(p) })
