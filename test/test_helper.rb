require "minitest/autorun"
require "minitest/reporters"
require "minitest/assert_errors"
require "rack/test"
require "mocha/minitest"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
include Rack::Test::Methods

ENV["RACK_ENV"] = "test"
ENV["WEBHOOK_URL"] = "https://test.example.com"
ENV["WEBHOOK_SECRET_PATH"] = "/super-secret-path"
ENV["TELEGRAM_TOKEN"] = "the-telegram-token"
