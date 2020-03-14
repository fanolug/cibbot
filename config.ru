# frozen_string_literal: true

require "./lib/cibbot/app"
Cibbot::App.new.init!

require "./lib/cibbot/telegram/webhook_server"
run Cibbot::Telegram::WebhookServer
