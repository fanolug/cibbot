# frozen_string_literal: true

require 'dotenv'
require './lib/cibbot/telegram/webhook_server'

Dotenv.load
run Cibbot::Telegram::WebhookServer
