# frozen_string_literal: true

require "dotenv/load"
require "sequel"
require "./lib/cibbot/telegram/webhook_server"

DB = if ENV["DATABASE_URL"]
  Sequel.connect(ENV["DATABASE_URL"])
else
  Sequel.sqlite # in-memory
end
run Cibbot::Telegram::WebhookServer
