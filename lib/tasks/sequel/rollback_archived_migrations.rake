# frozen_string_literal: true

require "sequel/timestamp_migrator_undo_extension"

namespace :sequel do
  desc "Rollback migrations that were applied earlier but are not present in current release"
  task rollback_archived_migrations: :environment do
    DB.log_info("Finding applied migrations not present in current release...")

    archive_path = Pathname.new(ENV.fetch("ARCHIVE_PATH")).expand_path.join("db/migrate")
    migrator = Sequel::TimestampMigrator.new(DB, archive_path, allow_missing_migration_files: true)

    applied_migrations = migrator.applied_migrations.map(&:to_i)
    filesystem_migrations = Rails.root.glob("db/migrate/*.rb").map { |x| File.basename(x).to_i }
    missing_migrations = applied_migrations - filesystem_migrations

    if missing_migrations.any?
      missing_migrations.each do |migration|
        DB.log_info("Rolling back migration #{migration}...")
        migrator.undo(migration)
      end
    else
      DB.log_info("No migrations found")
    end
  end
end
