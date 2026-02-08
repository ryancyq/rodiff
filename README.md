# rodiff

[![Version][rubygems_badge]][rubygems]
[![CI][ci_badge]][ci_workflows]
[![Coverage][coverage_badge]][coverage]
[![Maintainability][maintainability_badge]][maintainability]

A ruby image comparison tool powered by [Odiff](https://github.com/dmtrKovalenko/odiff) in OCamel.

## Motivation

Impressive [benchmarks](https://github.com/dmtrKovalenko/odiff#benchmarks) from `Odiff`.

A strong candidate against the veteran players like [pixelmatch](https://github.com/mapbox/pixelmatch) and [ImageMagick](https://github.com/ImageMagick/ImageMagick)

## Getting Started

Install the gem and add to the application's Gemfile by executing:
```sh
bundle add rodiff
```

If bundler is not being used to manage dependencies, install the gem by executing:
```sh
gem install rodiff
```

This gem wraps the [standalone executable](https://github.com/dmtrKovalenko/odiff#from-binaries) of the `Odiff`. These executables are platform specific, there are separate gems per platform, but the suitable gem will automatically be selected for your machine.

Supported platforms are:
- arm64-darwin (macos-arm64)
- x64-mingw32 (windows-x64)
- x64-mingw-ucrt (windows-x64)
- x86_64-darwin (macos-x64)
- x86_64-linux (linux-x64)

### Using a local installation of `Odiff`

If you are not able to use the vendored standalone executables, a local installation of the `Odiff` executable can be configured by setting an environment variable named `ODIFF_INSTALL_DIR` to the directory path containing the executable.

For example, if you've installed the [`odiff-bin`](https://github.com/dmtrKovalenko/odiff#cross-platform) npm package and had the binaries downloaded at `/path/to/node_modules/bin/odiff`, then you should set your environment variable like so:

``` sh
ODIFF_INSTALL_DIR=/path/to/node_modules/bin
```

or, for relative paths like `./node_modules/.bin/odiff`:

``` sh
ODIFF_INSTALL_DIR=node_modules/.bin
```

## Configuration

Rodiff automatically discovers and loads configuration from `.rodiff.yml` files in your project.

### Configuration File Discovery

Rodiff searches for `.rodiff.yml` starting from the current directory and traversing upward to your home directory:

```
/home/username/projects/myapp/src/tests/.rodiff.yml  ← checks here first
/home/username/projects/myapp/src/.rodiff.yml
/home/username/projects/myapp/.rodiff.yml            ← typically found here
/home/username/projects/.rodiff.yml
/home/username/.rodiff.yml                            ← stops here (home directory)
```

### Configuration Options

Create a `.rodiff.yml` file in your project root:

```yaml
# File patterns for image comparison (supports glob patterns)
include_pattern: "screenshots/**/*.png"
exclude_pattern: "screenshots/archived/**"

# Comparison settings
color_threshold: 0.1          # 0.0 - 1.0 (lower = stricter)
ignore_antialiasing: false    # Ignore antialiasing differences
output_diff_mask: false       # Output black/white mask instead of diff image

# Error handling
fail_if_no_comparison: false  # Exit with error if no images found
exit_code_error: 1           # Exit code for errors (not image differences)
```

### Programmatic Configuration

You can also configure Rodiff programmatically:

```ruby
Rodiff.configure do |config|
  config.include_pattern = "**/*.png"
  config.color_threshold = 0.15
  config.ignore_antialiasing = true
end
```

Or override specific values:

```ruby
config = Rodiff::Configuration.new
config.overrides(
  color_threshold: 0.2,
  output_diff_mask: true
)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `bundle exec rspec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and the created tag, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Troubleshooting

### `ERROR: Cannot find the odiff executable` for supported platform

Some users are reporting this error even when running on one of the supported platforms:
- arm64-darwin
- x64-mingw32
- x64-mingw-ucrt
- x86_64-darwin
- x86_64-linux

#### Check Bundler PLATFORMS

A possible cause of this is that Bundler has not been told to include gems for your current platform. Please check your `Gemfile.lock` file to see whether your native platform is included in the `PLATFORMS` section. If necessary, run:

``` sh
bundle lock --add-platform <platform-name>
```

and re-bundle.


#### Check BUNDLE_FORCE_RUBY_PLATFORM

Another common cause of this is that bundler is configured to always use the "ruby" platform via the
`BUNDLE_FORCE_RUBY_PLATFORM` config parameter being set to `true`. Please remove this configuration:

``` sh
bundle config unset force_ruby_platform
# or
bundle config set --local force_ruby_platform false
```

and re-bundle.

See https://bundler.io/man/bundle-config.1.html for more information.

## License

Rodiff is released under the [MIT License](https://opensource.org/licenses/MIT).
Odiff is released under the [MIT License](https://opensource.org/licenses/MIT).

## Contributing

Bug reports and pull requests are welcome on GitHub at [https://github.com/ryancyq/rodiff](https://github.com/ryancyq/rodiff).

[rubygems_badge]: https://img.shields.io/gem/v/rodiff.svg
[rubygems]: https://rubygems.org/gems/rodiff
[ci_badge]: https://github.com/ryancyq/rodiff/actions/workflows/ci.yml/badge.svg
[ci_workflows]: https://github.com/ryancyq/rodiff/actions/workflows/ci.yml
[coverage_badge]: https://codecov.io/gh/ryancyq/rodiff/graph/badge.svg?token=SYR7FSDWT5
[coverage]: https://codecov.io/gh/ryancyq/rodiff
[maintainability_badge]: https://api.codeclimate.com/v1/badges/d5b1002a1a7162f86a7a/maintainability
[maintainability]: https://codeclimate.com/github/ryancyq/rodiff/maintainability
