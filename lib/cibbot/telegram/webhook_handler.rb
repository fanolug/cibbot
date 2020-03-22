# frozen_string_literal: true

require "json"
require "telegram/bot"
require_relative "../models/user"
require_relative "client"

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
          send_welcome_message(message, menu_markup)
        when "/help"
          send_help_message(message)
        when "/users"
          send_users_list(message)
        when /^\/cibbe (.+)/i
          notify_users(message, $1)
        end
      end

      # @param message [Telegram::Bot::Types::CallbackQuery]
      def handle_callback_query(message)
        case message.data
        when CALLBACK_YES
          reply_to_yes(message)
        when CALLBACK_NO
          reply_to_no(message)
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
      def send_welcome_message(message, markup)
        text = "Ciao #{message.from.first_name}, benvenuto! #@wave"
        telegram.send_message(chat_id: message.chat.id, text: text, reply_markup: markup)
      end

      # @param message [Telegram::Bot::Types::Message]
      def send_help_message(message)
        text = "Help #@sos #@info:\n/cibbe <descrizione, luogo, orario, link eccetera> - Notifica la tua punta a tutti i cibbers"
        telegram.send_message(chat_id: message.chat.id, text: text)
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

      def menu_markup
        keyboard = [
          ::Telegram::Bot::Types::KeyboardButton.new(text: '/start'),
          ::Telegram::Bot::Types::KeyboardButton.new(text: '/help'),
          ::Telegram::Bot::Types::KeyboardButton.new(text: '/stop'),
        ]
        ::Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: keyboard, one_time_keyboard: true)
      end

      def mentioned_user(message)
        message.message.text.split(' ').each do | word |
          if word.include? "@"
            return word.split("@")[1]
          end
        end
      end

      def punta_message(message)
        message.message.text.split(':').values_at(1..-1).join(" ").strip
      end

      # @param message [Telegram::Bot::Types::CallbackQuery]
      def reply_to_yes(message)
        reply_chatid = Integer(Cibbot::User.where(username: mentioned_user(message)).get(:chat_id))
        from_chatid = message.from.id
        telegram.send_message(chat_id: from_chatid, text: "[reply-confirm] Hai confermato a @#{mentioned_user(message)} che vai a #{punta_message(message)} #@check #@callmegesture")
        telegram.send_message(chat_id: reply_chatid, text: "[reply-confirm] @#{message.from.username} viene a #{punta_message(message)} #@check #@lovehornsgesture")
        telegram.edit_message_text(chat_id: from_chatid, message_id: message.message.message_id, text: "#{message.message} #@check", reply_markup: nil)
      end

      # @param message [Telegram::Bot::Types::CallbackQuery]
      def reply_to_no(message)
        reply_chatid = Integer(Cibbot::User.where(username: mentioned_user(message)).get(:chat_id))
        from_chatid = message.from.id
        telegram.send_message(chat_id: from_chatid, text: "[reply-reject] Hai avvisato @#{mentioned_user(message)} che NON vai a #{punta_message(message)} #@uncheck")
        telegram.send_message(chat_id: reply_chatid, text: "[reply-reject] @#{message.from.username} NON viene a #{punta_message(message)} #@uncheck")
        telegram.edit_message_text(chat_id: from_chatid, message_id: message.message.message_id, text: "#{message.message} #@uncheck", reply_markup: nil)
      end

      # @param message [Telegram::Bot::Types::Message]
      def send_users_list(message)
        user_names = Cibbot::User.select_map(:username)
        telegram.send_message(chat_id: message.chat.id, text: user_names.join(", "))
      end
    end
  end
end
