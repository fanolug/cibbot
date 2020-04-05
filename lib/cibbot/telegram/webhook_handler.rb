# frozen_string_literal: true

require "json"
require "telegram/bot"
require_relative "../models/user"
require_relative "responder"

module Cibbot
  module Telegram
    class WebhookHandler
      CALLBACK_YES = "yes"
      CALLBACK_NO = "no"

      attr_reader :responder

      def initialize
        @responder = Cibbot::Telegram::Responder.new
      end

      # @param data [Hash] The request data
      def call(data)
        if data["message"]
          handle_message(telegram_message(data))
        elsif data["callback_query"]
          handle_callback_query(telegram_callback_query(data))
        end
      end

      private

      # @param data [JSON] The message data
      # @return [Telegram::Bot::Types::Message] The Telegram message
      def telegram_message(data)
        ::Telegram::Bot::Types::Message.new(data["message"])
      end

      # @param data [JSON] The message data
      # @return [Telegram::Bot::Types::CallbackQuery] The Telegram callback query
      def telegram_callback_query(data)
        ::Telegram::Bot::Types::CallbackQuery.new(data["callback_query"])
      end

      # @param message [Telegram::Bot::Types::Message]
      def handle_message(message)
        chat_id = message.chat.id
        name = message.from.first_name

        case message.text
        when "/start"
          save_user!(message)
          responder.send_welcome_message(name: name, chat_id: chat_id)
        when "/help"
          responder.send_help_message(chat_id: chat_id)
        when "/stop"
          delete_user!(message)
          responder.send_goodbye_message(name: name, chat_id: chat_id)
        when "/users"
          responder.send_users_list(chat_id: chat_id)
        when /^\/cibbe (.+)/i
          notify_users(message, $1)
        end
      end

      # @param message [Telegram::Bot::Types::CallbackQuery]
      def handle_callback_query(message)
        case message.data
        when CALLBACK_YES
          responder.reply_to_yes(message)
        when CALLBACK_NO
          responder.reply_to_no(message)
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
      def delete_user!(message)
        user = Cibbot::User.find(chat_id: message.chat.id.to_s)
        user&.delete
      end

      # @param message [Telegram::Bot::Types::Message]
      # @param text [String]
      def notify_users(message, text)
        users = Cibbot::User.exclude(chat_id: message.from.id.to_s)
        users.each do |user|
          responder.send_cibbe(
            username: message.from.username,
            text: text,
            chat_id: user.chat_id
          )
        end

        responder.send_cibbe_feedback(chat_id: message.from.id, count: users.count)
      end
    end
  end
end
