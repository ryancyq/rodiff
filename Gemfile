# frozen_string_literal: true

source "https://rubygems.org"

gemspec

group :development, :test do
  gem "rake", "~> 13.0"
  gem "rspec", "~> 3.12"
end

group :development do
  gem "rubocop", "~> 1.65", require: false
  gem "rubocop-rake", require: false
  gem "rubocop-rspec", require: false
end

group :test do
  gem "vcr", "~> 6.3"
  gem "webmock", "~> 3.23"
end
