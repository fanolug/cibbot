# frozen_string_literal: true

require "rake/testtask"

Rake::TestTask.new do |t|
  t.test_files = FileList["test/**/test_*.rb"]
  t.warning = false
end
desc "Run tests"

namespace :db do
  require "sequel/core"
  require_relative "lib/cibbot/db"

  Sequel.extension :migration
  dir = "db/migrate"

  desc "Prints current schema version"
  task :version do
    version = if DB.tables.include?(:schema_info)
      DB[:schema_info].first[:version]
    end || 0

    puts "Schema Version: #{version}"
  end

  desc "Run migrations"
  task :migrate do
    Sequel::Migrator.run(DB, dir)
    Rake::Task["db:version"].execute
  end

  desc "Perform rollback to specified target or full rollback as default"
  task :rollback, :target do |t, args|
    args.with_defaults(target: 0)

    Sequel::Migrator.run(DB, dir, target: args[:target].to_i)
    Rake::Task["db:version"].execute
  end

  desc "Perform migration reset (full rollback and migration)"
  task :reset do
    Sequel::Migrator.run(DB, dir, target: 0)
    Sequel::Migrator.run(DB, dir)
    Rake::Task["db:version"].execute
  end
end

task default: :test
