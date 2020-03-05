require_relative '../test_helper'
require_relative '../../lib/cibbot/telegram/webhook_server'

describe Cibbot::Telegram::WebhookServer do
  let(:app) { Cibbot::Telegram::WebhookServer }

  describe 'GET /' do
    it 'returns a static text' do
      get '/'
      _(last_response.ok?).must_equal(true)
      _(last_response.body).must_equal('Cibbot by FortunaeLUG')
    end
  end
end
