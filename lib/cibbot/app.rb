# frozen_string_literal: true

require "dotenv/load"
require_relative "../logging"
require_relative "telegram/client"

module Cibbot
  class App
    include Logging
    include Cibbot::Telegram::Client

    REQUIRED_ENV_VARS = %w[
      DATABASE_URL WEBHOOK_SECRET_PATH WEBHOOK_URL TELEGRAM_TOKEN
    ].freeze

    def init!
      validate_env!
      init_telegram_webhook!
      true
    end

    private

    def validate_env!
      missing_vars = REQUIRED_ENV_VARS.filter { |var| !ENV[var] }

      if missing_vars.any?
        raise "Some ENV variables are missing: #{missing_vars.join(', ')}"
      end
    end

    def init_telegram_webhook!
      result = telegram.set_webhook(url: webhook_endpoint)
      logger.info "Setting Telegram webhook URL (#{ENV['WEBHOOK_URL']})"
      logger.info "=> #{result['description']}"
    end

    def webhook_endpoint
      "#{ENV['WEBHOOK_URL']}#{ENV['WEBHOOK_SECRET_PATH']}"
    end
  end
end
