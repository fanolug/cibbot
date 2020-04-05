require_relative "../../test_helper"
require_relative "../../../lib/cibbot/telegram/responder"

describe Cibbot::Telegram::Responder do
  let(:instance) { Cibbot::Telegram::Responder.new }
  let(:telegram_message) do
    ::Telegram::Bot::Types::Message.new(
      from: telegram_user,
      chat: telegram_chat
    )
  end
  let(:telegram_callback_query) do
    ::Telegram::Bot::Types::CallbackQuery.new(
      from: telegram_user,
      chat: telegram_chat,
      message: ::Telegram::Bot::Types::Message.new(
        id: 12345,
        from: telegram_bot,
        chat: telegram_chat,
        text: "@test_user"
      )
    )
  end
  let(:telegram_user) { ::Telegram::Bot::Types::User.new(id: 1, username: "pippo", first_name: "Pippo") }
  let(:telegram_bot) { ::Telegram::Bot::Types::User.new(id: 2, username: "bot", first_name: "Cibbot test") }
  let(:telegram_chat) { ::Telegram::Bot::Types::Chat.new(id: 666) }

  describe "#send_welcome_message" do
    it "sends the message" do
      ::Telegram::Bot::Api.any_instance.expects(:send_message).with do |args|
        args[:chat_id] == 666
        args[:text].match? /Ciao Pippo, benvenuto!/
        args[:reply_markup].kind_of? ::Telegram::Bot::Types::ReplyKeyboardMarkup
      end
      instance.send_welcome_message(telegram_message)
    end
  end

  describe "#send_goodbye_message" do
    it "sends the message" do
      ::Telegram::Bot::Api.any_instance.expects(:send_message).with do |args|
        args[:chat_id] == 666
        args[:text].match? /Ciao Pippo, ci dispiace vederti andare via/
        args[:reply_markup].kind_of? ::Telegram::Bot::Types::ReplyKeyboardRemove
      end
      instance.send_goodbye_message(telegram_message)
    end
  end

  describe "#send_help_message" do
    it "sends the message" do
      ::Telegram::Bot::Api.any_instance.expects(:send_message).with do |args|
        args[:chat_id] == 666
        args[:text].match? /Help/
      end
      instance.send_help_message(telegram_message)
    end
  end

  describe "#send_users_list" do
    before do
      Cibbot::User.create username: "test_user", first_name: "Name", chat_id: 111
      Cibbot::User.create username: "test_user2", first_name: "Name", chat_id: 222
    end

    it "sends the message" do
      ::Telegram::Bot::Api.any_instance.expects(:send_message).with do |args|
        args[:chat_id] == 666
        args[:text] == "test_user, test_user2"
      end
      instance.send_users_list(telegram_message)
    end
  end

  describe "#reply_to_yes" do
    before do
      Cibbot::User.create username: "test_user", first_name: "Test Name", chat_id: 111
    end

    it "sends the messages" do
      ::Telegram::Bot::Api.any_instance.expects(:send_message).with do |args|
        args[:chat_id] == 666
        args[:text].match? /Hai confermato a @test_user che vai a/
      end

      ::Telegram::Bot::Api.any_instance.expects(:send_message).with do |args|
        args[:chat_id] == 111
        args[:text].match? /@pippo viene a/
      end

      ::Telegram::Bot::Api.any_instance.expects(:edit_message_text).with do |args|
        args[:chat_id] == 12345
        args[:reply_markup].nil?
      end

      instance.reply_to_yes(telegram_callback_query)
    end
  end

  describe "#reply_to_no" do
    before do
      Cibbot::User.create username: "test_user", first_name: "Test Name", chat_id: 111
    end

    it "sends the messages" do
      ::Telegram::Bot::Api.any_instance.expects(:send_message).with do |args|
        args[:chat_id] == 666
        args[:text].match? /Hai avvisato @test_user che NON vai a/
      end

      ::Telegram::Bot::Api.any_instance.expects(:send_message).with do |args|
        args[:chat_id] == 111
        args[:text].match? /@pippo NON viene a/
      end

      ::Telegram::Bot::Api.any_instance.expects(:edit_message_text).with do |args|
        args[:chat_id] == 12345
        args[:reply_markup].nil?
      end

      instance.reply_to_no(telegram_callback_query)
    end
  end
end
