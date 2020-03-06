# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}" }

ruby "~> 2.7.0"

gem "sinatra", "~> 2.0.8"
gem "puma", "~> 4.3.3"
gem "dotenv", "~> 2.7.5"
gem "telegram-bot-ruby", "~> 0.12.0"
gem "sequel", "~> 5.30.0"
gem "rake", "~> 13.0.1"

group :production do
  gem "pg", "~> 1.2.2"
end

group :development do
  gem "sqlite3", "1.4.2"
  gem "minitest", "~> 5.14"
  gem "minitest-reporters", "~> 1.4"
  gem "rack-test", "~> 1.1"
  gem "mocha", "~> 1.11.2"
end
