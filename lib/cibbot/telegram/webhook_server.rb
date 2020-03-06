# frozen_string_literal: true

require 'sinatra/base'
require 'json'
require 'telegram/bot'
require_relative 'webhook_handler'

module Cibbot
  module Telegram
    class WebhookServer < Sinatra::Base
      enable :logging

      get '/' do
        'Cibbot by FortunaeLUG'
      end

      # Handle webhooks coming from Telegram
      post ENV['SECRET_WEBHOOK_PATH'] do
        webhook_handler.call(parsed_body(request))
        200
      end

      private

      # @param message [Sinatra::Request] The raw HTTP request
      # @return [JSON] The parsed request body
      def parsed_body(request)
        JSON.parse(request.body.read)
      end

      def webhook_handler
        @webhook_handler ||= WebhookHandler.new
      end
    end
  end
end
