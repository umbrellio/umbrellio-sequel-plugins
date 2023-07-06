# frozen_string_literal: true

require "sequel/timestamp_migrator_undo_extension"

namespace :sequel do
  # Rollback migrations that are applied and not present in current release but present in archive
  task rollback_archived_migrations: :environment do
    puts "Finding applied migrations not present in current release..."

    archive_path = Pathname.new(ENV.fetch("ARCHIVE_PATH")).expand_path.join("db/migrate")
    migrator = Sequel::TimestampMigrator.new(DB, archive_path, allow_missing_migration_files: true)

    applied_migrations = migrator.applied_migrations.map(&:to_i)
    current_migrations = Rails.root.glob("db/migrate/*.rb").map { |x| File.basename(x).to_i }
    missing_migrations = applied_migrations - current_migrations

    if missing_migrations.any?
      missing_migrations.each do |migration|
        puts "Rolling back migration #{migration}..."
        migrator.undo(migration)
      end
    else
      puts "No migrations found"
    end
  end
end
