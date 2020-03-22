# frozen_string_literal: true

require "dotenv/load"
require "sequel"
require_relative "../logging"

include Logging

Sequel.extension :migration
Sequel::Model.plugin :timestamps

DB = Sequel.connect(ENV["DATABASE_URL"])
DB.loggers = [logger]
DB.sql_log_level = :debug
