require 'minitest/autorun'
require 'minitest/reporters'
require 'rack/test'
require "mocha/minitest"

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
include Rack::Test::Methods

ENV['RACK_ENV'] = 'test'
ENV['SECRET_WEBHOOK_PATH'] = '/super-secret-path'
