# frozen_string_literal: true

require_relative "lib/rodiff/version"

Gem::Specification.new do |spec|
  spec.name = "rodiff"
  spec.version = Rodiff::VERSION
  spec.authors = ["Ryan Chang"]
  spec.email = ["ryancyq@gmail.com"]

  spec.summary     = "A ruby wrapper for odiff"
  spec.homepage    = "https://github.com/ryancyq/rodiff"
  spec.license     = "MIT"

  spec.metadata = {
    "rubygems_mfa_required" => "true",
    "allowed_push_host"     => "https://rubygems.org",
    "changelog_uri"         => "https://github.com/ryancyq/rodiff/blob/main/CHANGELOG.md",
    "homepage_uri"          => spec.homepage
  }

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = IO.popen(%w[git ls-files -z], chdir: __dir__, err: IO::NULL) do |ls|
    ls.readlines("\x0", chomp: true).select do |f|
      f.start_with?(*%w[lib/ exe/ LICENSE README.md])
    end
  end

  spec.bindir = "exe"
  spec.executables = spec.files.grep(%r{\Aexe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.required_ruby_version = "~> 3.0"
  spec.requirements << "odiff #{Rodiff::ODIFF_VERSION}"
  spec.add_dependency "thor", "~> 1.3.2"
end
