# frozen_string_literal: true

require "dotenv/load"
require "telegram/bot"
require_relative "../../logging"

module Cibbot
  module Telegram
    module Client
      include Logging

      # @return [Telegram::Bot::Api] The Telegram API client
      def telegram
        @telegram ||= ::Telegram::Bot::Client.new(
          ENV["TELEGRAM_TOKEN"],
          logger: logger
        ).api
      rescue Telegram::Bot::Exceptions::ResponseError
      end
    end
  end
end
