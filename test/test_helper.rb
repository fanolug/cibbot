require "minitest/autorun"
require "minitest/reporters"
require "minitest/assert_errors"
require "minitest/hooks/default"
require "rack/test"
require "mocha/minitest"

ENV["DATABASE_URL"] = "sqlite://test.db"
require_relative "../lib/cibbot/db"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
include Rack::Test::Methods

ENV["RACK_ENV"] = "test"
ENV["WEBHOOK_URL"] = "https://test.example.com"
ENV["WEBHOOK_SECRET_PATH"] = "/super-secret-path"
ENV["TELEGRAM_TOKEN"] = "the-telegram-token"

class Minitest::Spec
  Sequel::Migrator.run(DB, "db/migrate")
end

class Minitest::HooksSpec
  def around
    DB.transaction(rollback: :always, auto_savepoint: true) { super }
  end
end
