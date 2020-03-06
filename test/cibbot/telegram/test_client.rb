require_relative "../../test_helper"
require_relative "../../../lib/cibbot/telegram/client"

describe Cibbot::Telegram::Client do
  let(:instance) { Class.new { include Cibbot::Telegram::Client }.new }

  describe "#telegram" do
    it "returns a telegram client" do
      _(instance.telegram.class).must_equal ::Telegram::Bot::Api
    end

    it "uses the ENV token" do
      _(instance.telegram.token).must_equal "the-telegram-token"
    end
  end
end
