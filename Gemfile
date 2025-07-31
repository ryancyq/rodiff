# frozen_string_literal: true

source "https://rubygems.org"

gemspec

gem "thor", "~> 1.3.2"

group :development, :test do
  gem "rake", "~> 13.3"
  gem "rspec", "~> 3.12"

  gem "simplecov", "~> 0.22.0", require: false
  gem "simplecov-cobertura", require: false
end

group :development do
  gem "rubocop", "~> 1.79", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
end

group :test do
  gem "vcr", "~> 6.3"
  gem "webmock", "~> 3.25"
end
