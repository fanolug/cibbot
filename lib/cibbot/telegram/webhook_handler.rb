# frozen_string_literal: true

require 'json'
require 'telegram/bot'

module Cibbot
  module Telegram
    class WebhookHandler
      # @param data [JSON] The request data
      def call(data)
        telegram_message(data)
        # TODO do something
      end

      private

      # @param data [JSON] The message data
      # @return [Telegram::Bot::Types::Message] The Telegram message
      def telegram_message(data)
        ::Telegram::Bot::Types::Message.new(data["message"])
      end
    end
  end
end
