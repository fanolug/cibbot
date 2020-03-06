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
      end
    end
  end
end
