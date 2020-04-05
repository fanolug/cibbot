# frozen_string_literal: true

require "json"
require "telegram/bot"
require_relative "../models/user"
require_relative "client"
require_relative "responder"

module Cibbot
  module Telegram
    class WebhookHandler
      include Cibbot::Telegram::Client

      CALLBACK_YES = "yes"
      CALLBACK_NO = "no"

      def initialize
        # unicode emoji
        @sos = "\u{1F198}"
        @wave = "\u{1F44B}"
        @info = "\u{2139}"
        @pushpin = "\u{1F4CD}"
        @calendar = "\u{1F4C5}"
        @check = "\u{2705}"
        @uncheck = "\u{274C}"
        @cry = "\u{1F622}"
        @lovehornsgesture = "\u{1F91F}"
        @callmegesture = "\u{1F919}"
        @likegesture = "\u{1F44D}"
      end

      # @param data [JSON] The request data
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
        case message.text
        when "/start"
          save_user!(message)
          responder.send_welcome_message(message)
        when "/help"
          responder.send_help_message(message)
        when "/stop"
          delete_user!(message)
          responder.send_goodbye_message(message)
        when "/users"
          responder.send_users_list(message)
        when /^\/cibbe (.+)/i
          notify_users(message, $1)
        end
      end

      # @param message [Telegram::Bot::Types::CallbackQuery]
      def handle_callback_query(message)
        pp message
        case message.data
        when CALLBACK_YES
          responder.reply_to_yes(message)
        when CALLBACK_NO
          responder.reply_to_no(message)
        end
      end

      def responder
        Cibbot::Telegram::Responder.new
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
        user.delete
      end

      # @param message [Telegram::Bot::Types::Message]
      def notify_users(message, info)
        text = "#@pushpin #@calendar @#{message.from.username} ha chiesto se vieni: #{info}"
        Cibbot::User.exclude(chat_id: message.from.id.to_s).each do |user|
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
