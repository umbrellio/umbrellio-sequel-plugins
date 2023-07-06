# frozen_string_literal: true

require "sequel/timestamp_migrator_undo_extension"

namespace :sequel do
  # Rollback migrations that are applied and not present in current release but present in archive
  task rollback_archived_migrations: :environment do
    def extract_migrations(path)
      path.glob("*.rb").map { |filename| File.basename(filename).to_i }
    end

    puts "Rolling back migrations not present in current release"

    archive_path = Pathname.new(ENV.fetch("ARCHIVE_PATH")).expand_path.join("db/migrate")
    current_path = Rails.root.join("db/migrate")

    all_migrations = extract_migrations(archive_path)
    current_migrations = extract_migrations(current_path)
    candidate_migrations = all_migrations - current_migrations

    next if candidate_migrations.empty?

    puts "Candidate migrations:"
    puts candidate_migrations

    migrator = Sequel::TimestampMigrator.new(DB, archive_path, allow_missing_migration_files: true)
    applied_migrations = migrator.applied_migrations.map(&:to_i).to_set
    migrations_to_rollback =
      applied_migrations.select { |x| x.in?(candidate_migrations) }.sort.reverse

    next if migrations_to_rollback.empty?

    puts "Rolling back migrations:"
    puts migrations_to_rollback

    migrations_to_rollback.each { |x| migrator.undo(x) }
  end
end
