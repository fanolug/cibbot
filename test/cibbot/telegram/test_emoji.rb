require_relative "../../test_helper"
require_relative "../../../lib/cibbot/telegram/emoji"

describe Cibbot::Telegram::Emoji do
  let(:instance) { Class.new { include Cibbot::Telegram::Emoji }.new }

  describe "#emoji" do
    it "returns a known emoji UTF code" do
      _(instance.emoji(:sos)).must_equal "\u{1F198}"
    end

    it "returns nil " do
      _(instance.emoji(:wrong_name)).must_be_nil
    end
  end
end
