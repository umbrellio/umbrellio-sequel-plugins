# frozen_string_literal: true

require "sequel/timestamp_migrator_undo_extension"

namespace :sequel do
  desc "Rollback a specific migration"
  task undo: :environment do
    version = ENV["VERSION"]&.to_i
    raise "VERSION is required" unless version

    path = Rails.root.join("db/migrate")
    migrator = Sequel::TimestampMigrator.new(DB, path, allow_missing_migration_files: true)
    migrator.undo(version)
  end
end
