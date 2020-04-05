# frozen_string_literal: true

require "json"
require "telegram/bot"
require_relative "../models/user"
require_relative "client"
require_relative "emoji"

module Cibbot
  module Telegram
    class Responder
      include Cibbot::Telegram::Client
      include Cibbot::Telegram::Emoji

      # @param chat_id [Integer]
      # @param name [String]
      def send_welcome_message(chat_id:, name:)
        text = "Ciao #{name}, benvenuto! #{emoji(:wave)}"
        telegram.send_message(
          chat_id: chat_id,
          text: text,
          reply_markup: menu_markup
        )
      end

      # @param chat_id [Integer]
      # @param name [String]
      def send_goodbye_message(chat_id:, name:)
        text = "Ciao #{name}, ci dispiace vederti andare via #{emoji(:cry)}!"
        telegram.send_message(
          chat_id: chat_id,
          text: text,
          reply_markup: remove_menu_markup
        )
      end

      # @param chat_id [Integer]
      def send_help_message(chat_id:)
        text = "Help #{emoji(:sos)} #{emoji(:info)}:\n/cibbe <descrizione, luogo, orario, link eccetera> - Notifica la tua punta a tutti i cibbers"
        telegram.send_message(chat_id: chat_id, text: text)
      end

      # @param chat_id [Integer]
      def send_users_list(chat_id:)
        user_names = Cibbot::User.select_map(:username).join(", ")
        telegram.send_message(chat_id: chat_id, text: user_names)
      end

      # @param username [String]
      # @param text [String]
      # @param chat_id [Integer]
      def send_cibbe(username:, text:, chat_id:)
        text = "#{emoji(:pushpin)} #{emoji(:calendar)} @#{username} ha chiesto se vieni: #{text}"
        telegram.send_message(
          chat_id: chat_id,
          text: text,
          reply_markup: notification_markup
        )
      end

      # @param chat_id [Integer]
      # @param count [Integer]
      def send_cibbe_feedback(chat_id:, count:)
        text = "L'invito è stato mandato a #{count} persone."
        telegram.send_message(chat_id: chat_id, text: text)
      end

      # @param message [Telegram::Bot::Types::CallbackQuery]
      def reply_to_yes(message)
        reply_chatid = Integer(Cibbot::User.where(username: mentioned_user(message.message.text)).get(:chat_id))
        from_chatid = message.from.id
        telegram.send_message(
          chat_id: from_chatid,
          text: "[reply-confirm] Hai confermato a @#{mentioned_user(message.message.text)} che vai a #{punta_message(message.message.text)} #{emoji(:check)} #{emoji(:callme)}"
        )
        telegram.send_message(
          chat_id: reply_chatid,
          text: "[reply-confirm] @#{message.from.username} viene a #{punta_message(message.message.text)} #{emoji(:check)} #{emoji(:lovehorns)}")
        telegram.edit_message_text(
          chat_id: from_chatid,
          message_id: message.message.message_id,
          text: "#{message.message} #{emoji(:check)}",
          reply_markup: nil
        )
      end

      # @param message [Telegram::Bot::Types::CallbackQuery]
      def reply_to_no(message)
        reply_chatid = Integer(Cibbot::User.where(username: mentioned_user(message.message.text)).get(:chat_id))
        from_chatid = message.from.id
        telegram.send_message(
          chat_id: from_chatid,
          text: "[reply-reject] Hai avvisato @#{mentioned_user(message.message.text)} che NON vai a #{punta_message(message.message.text)} #{emoji(:uncheck)}"
        )
        telegram.send_message(
          chat_id: reply_chatid,
          text: "[reply-reject] @#{message.from.username} NON viene a #{punta_message(message.message.text)} #{emoji(:uncheck)}"
        )
        telegram.edit_message_text(
          chat_id: from_chatid,
          message_id: message.message.message_id,
          text: "#{message.message} #{emoji(:uncheck)}",
          reply_markup: nil
        )
      end

      private

      def mentioned_user(text)
        text.split(" ").each do | word |
          if word.include? "@"
            return word.split("@")[1]
          end
        end
      end

      def punta_message(text)
        text.split(":").values_at(1..-1).join(" ").strip
      end

      def menu_markup
        keyboard = [
          ::Telegram::Bot::Types::KeyboardButton.new(text: "/start"),
          ::Telegram::Bot::Types::KeyboardButton.new(text: "/help"),
          ::Telegram::Bot::Types::KeyboardButton.new(text: "/stop"),
        ]
        ::Telegram::Bot::Types::ReplyKeyboardMarkup.new(
          keyboard: keyboard,
          one_time_keyboard: true
        )
      end

      def remove_menu_markup
        ::Telegram::Bot::Types::ReplyKeyboardRemove.new(remove_keyboard: true)
      end

      def notification_markup
        keyboard = [
          ::Telegram::Bot::Types::InlineKeyboardButton.new(
            text: "Ci vengo!",
            callback_data: "yes"
          ),
          ::Telegram::Bot::Types::InlineKeyboardButton.new(
            text: "Non vengo.",
            callback_data: "no"
          ),
        ]
        ::Telegram::Bot::Types::InlineKeyboardMarkup.new(
          inline_keyboard: keyboard
        )
      end
    end
  end
end
