# frozen_string_literal: true

require 'sinatra/base'

module Cibbot
  module Telegram
    class WebhookServer < Sinatra::Base
      enable :logging

      get '/' do
        'Cibbot by FortunaeLUG'
      end
    end
  end
end
