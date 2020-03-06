require_relative '../../test_helper'
require_relative '../../../lib/cibbot/telegram/webhook_server'

describe Cibbot::Telegram::WebhookServer do
  let(:app) { Cibbot::Telegram::WebhookServer }

  describe 'GET /' do
    it 'returns a static text' do
      get '/'
      _(last_response.ok?).must_equal(true)
      _(last_response.body).must_equal('Cibbot by FortunaeLUG')
    end
  end

  describe "POST /super-secret-path (set on ENV)" do
    it "returns 200" do
      post "/super-secret-path", "{}"
      _(last_response.ok?).must_equal(true)
      _(last_response.body).must_equal("")
    end

    it "calls the handler" do
      Cibbot::Telegram::WebhookHandler.any_instance.expects(:call)
      post "/super-secret-path", "{}"
    end
  end
end
