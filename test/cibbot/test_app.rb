require_relative "../test_helper"
require_relative "../../lib/cibbot/app"

describe Cibbot::App do
  let(:instance) { Cibbot::App.new }
  let(:webhook_endpoint) { "https://test.example.com/super-secret-path" }
  let(:set_webhook_response) do
    {"ok" => true, "result" => true, "description" => "Webhook was set"}
  end

  describe "#init!" do
    before do
      ::Telegram::Bot::Api.any_instance.stubs(:set_webhook).with(
        url: webhook_endpoint
      ).returns(set_webhook_response)
    end

    it "returns true" do
      _(instance.init!).must_equal true
    end

    describe "with missing ENV variables" do
      before { ENV.stubs(:[]).returns(nil) }

      it "raises an error" do
        assert_error_raised(/Some ENV variables are missing/, RuntimeError) do
          instance.init!
        end
      end
    end

    it "sets up the Telegram webhook" do
      ::Telegram::Bot::Api.any_instance.expects(:set_webhook).with(
        url: webhook_endpoint
      ).returns(set_webhook_response)
      instance.init!
    end
  end
end
