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

      # @param callback_query [Telegram::Bot::Types::CallbackQuery]
      def reply_to_yes(callback_query)
        reply(
          callback_query: callback_query,
          sender_reply: "[reply-confirm] Hai confermato a @#{mentioned_user(callback_query.message.text)} che vai a #{punta_message(callback_query.message.text)} #{emoji(:check)} #{emoji(:callme)}",
          host_reply: "[reply-confirm] @#{callback_query.from.username} viene a #{punta_message(callback_query.message.text)} #{emoji(:check)} #{emoji(:lovehorns)}"
        )
      end

      # @param callback_query [Telegram::Bot::Types::CallbackQuery]
      def reply_to_no(callback_query)
        reply(
          callback_query: callback_query,
          sender_reply: "[reply-reject] Hai avvisato @#{mentioned_user(callback_query.message.text)} che NON vai a #{punta_message(callback_query.message.text)} #{emoji(:uncheck)}",
          host_reply: "[reply-reject] @#{callback_query.from.username} NON viene a #{punta_message(callback_query.message.text)} #{emoji(:uncheck)}"
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

      def reply(callback_query:, sender_reply:, host_reply:)
        username = mentioned_user(callback_query.message.text)
        user = Cibbot::User.where(username: username)
        reply_chat_id = user.get(:chat_id)

        telegram.send_message(chat_id: callback_query.from.id, text: sender_reply)
        telegram.send_message(chat_id: reply_chat_id, text: host_reply)
        telegram.delete_message(
          chat_id: callback_query.from.id,
          message_id: callback_query.message.message_id
        )
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
