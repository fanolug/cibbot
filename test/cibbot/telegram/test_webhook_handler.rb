require_relative '../../test_helper'
require_relative '../../../lib/cibbot/telegram/webhook_handler'

describe Cibbot::Telegram::WebhookHandler do
  let(:instance) { Cibbot::Telegram::WebhookHandler.new }
  let(:responder) { instance.responder }

  describe '#call' do
    let(:call) { instance.call(data) }
    let(:user_data) { { "id" => "666", "username" => "pippo", "first_name" => "Pippo" } }

    describe "with a message" do
      let(:data) do
        {
          "message" => {
            "from" => user_data,
            "chat" => user_data,
            "text" => text,
          }
        }
      end

      describe "/start command" do
        let(:text) { "/start" }

        it "saves the user on the DB" do
          responder.expects(:send_welcome_message)

          _(Cibbot::User.count).must_equal 0
          call
          _(Cibbot::User.count).must_equal 1
          _(Cibbot::User.last.username).must_equal "pippo"
        end

        it "sends the message" do
          responder.expects(:send_welcome_message).with(chat_id: 666, name: "Pippo")
          call
        end
      end

      describe "/help command" do
        let(:text) { "/help" }

        it "sends the message" do
          responder.expects(:send_help_message).with(chat_id: 666)
          call
        end
      end

      describe "/stop command" do
        let(:text) { "/stop" }

        before do
          Cibbot::User.create(chat_id: 666, username: "pippo", first_name: "Pippo")
        end

        it "deletes the user from the DB" do
          responder.expects(:send_goodbye_message)

          _(Cibbot::User.count).must_equal 1
          call
          _(Cibbot::User.count).must_equal 0
        end

        it "sends the message" do
          responder.expects(:send_goodbye_message).with(chat_id: 666, name: "Pippo")
          call
        end
      end

      describe "/users command" do
        let(:text) { "/users" }

        it "sends the message" do
          responder.expects(:send_users_list).with(chat_id: 666)
          call
        end
      end

      describe "/cibbe command" do
        let(:text) { "/cibbe somewehere" }

        before do
          Cibbot::User.create(chat_id: 999, username: "lino", first_name: "Lino")
        end

        it "sends the messages" do
          responder.expects(:send_cibbe).with do |args|
            args[:username] = "lino"
            args[:text] == "somewehere"
            args[:chat_id] == "999"
          end
          responder.expects(:send_cibbe_feedback).with do |args|
            args[:chat_id] == 666
            args[:count] == 1
          end
          call
        end
      end
    end

    describe "with a callback query" do
      let(:data) do
        {
          "callback_query" => {
            "from" => user_data,
            "data" => response,
          }
        }
      end

      describe "yes response" do
        let(:response) { "yes" }

        it "sends the message" do
          responder.expects(:reply_to_yes).with do |arg|
            arg.kind_of? ::Telegram::Bot::Types::CallbackQuery
          end
          call
        end
      end

      describe "no response" do
        let(:response) { "no" }

        it "sends the message" do
          responder.expects(:reply_to_no).with do |arg|
            arg.kind_of? ::Telegram::Bot::Types::CallbackQuery
          end
          call
        end
      end
    end
  end
end
