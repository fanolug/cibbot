require 'minitest/autorun'
require 'minitest/reporters'
require 'rack/test'

Minitest::Reporters.use! Minitest::Reporters::SpecReporter.new
include Rack::Test::Methods

ENV['RACK_ENV'] = 'test'
