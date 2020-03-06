# frozen_string_literal: true

require "dotenv/load"
require "sequel"

DB = Sequel.connect(ENV["DATABASE_URL"])
