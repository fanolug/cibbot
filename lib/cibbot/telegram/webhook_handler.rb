# frozen_string_literal: true

require "json"
require "telegram/bot"
require_relative "../models/user"
require_relative "client"

module Cibbot
  module Telegram
    class WebhookHandler
      include Cibbot::Telegram::Client

      # @param data [JSON] The request data
      def call(data)
        handle_message(telegram_message(data))
      end

      private

      # @param data [JSON] The message data
      # @return [Telegram::Bot::Types::Message] The Telegram message
      def telegram_message(data)
        ::Telegram::Bot::Types::Message.new(data["message"])
      end

      # @param message [Telegram::Bot::Types::Message]
      def handle_message(message)
        case message.text
        when "/start"
          save_user!(message)
          send_welcome_message(message)
        when "/help"
          send_help_message(message)
        when /^\/cibbe (.+)/i
          notify_users(message, $1)
        end
      end

      # @param message [Telegram::Bot::Types::Message]
      def save_user!(message)
        user = Cibbot::User.find(chat_id: message.chat.id.to_s) ||
          Cibbot::User.new(chat_id: message.chat.id.to_s)

        user.set(
          username: message.from.username,
          first_name: message.from.first_name,
          last_name: message.from.last_name,
        )
        user.save
      end

      # @param message [Telegram::Bot::Types::Message]
      def send_welcome_message(message)
        text = "Ciao #{message.from.first_name}, benvenuto!"
        telegram.send_message(chat_id: message.chat.id, text: text)
      end

      # @param message [Telegram::Bot::Types::Message]
      def send_help_message(message)
        text = "Help:\n/cibbe <descrizione, luogo, orario, link eccetera> - Notifica la tua punta a tutti i cibbers"
        telegram.send_message(chat_id: message.chat.id, text: text)
      end

      # @param message [Telegram::Bot::Types::Message]
      def notify_users(message, info)
        text = "@#{message.from.username} ha chiesto se vieni: #{info}"
        Cibbot::User.exclude(chat_id: message.from.id).each do |user|
          telegram.send_message(
            chat_id: user.chat_id,
            text: text,
            reply_markup: notification_markup,
          )
        end
      end

      def button(**args)
        ::Telegram::Bot::Types::InlineKeyboardButton.new(args)
      end

      def notification_markup
        keyboard = [
          button(text: "Ci vengo!", callback_data: "yes"),
          button(text: "Non vengo.", callback_data: "no"),
        ]
        ::Telegram::Bot::Types::InlineKeyboardMarkup.new(
          inline_keyboard: keyboard
        )
      end
    end
  end
end
