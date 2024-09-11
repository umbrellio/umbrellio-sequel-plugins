# frozen_string_literal: true

require "sequel/timestamp_migrator_undo_extension"

namespace :sequel do
  desc "Rollback migrations that were applied earlier but are not present in current release"
  task :rollback_archived_migrations,
       [:migrations_path, :migration_table, :migration_table_source,
        :use_transactions] => :environment do |_t, args|
    migrations_path = args[:migrations_path] || "db/migrate/*.rb"
    migration_table_source = args[:migration_table_source].to_sym || :schema_migrations_sources
    use_transactions = args[:use_transactions].nil? ? nil : args[:use_transactions] == "true"

    DB.log_info("Finding applied migrations not present in current release...")

    Dir.mktmpdir do |tmpdir|
      DB[migration_table_source].each do |migration|
        path = File.join(tmpdir, migration.fetch(:filename))
        File.write(path, migration.fetch(:source))
      end

      migrator_args = {
        table: args[:migration_table],
        use_transactions: use_transactions,
        allow_missing_migration_files: false,
      }.compact
      migrator = Sequel::TimestampMigrator.new(DB, tmpdir, migrator_args)

      applied_migrations = migrator.applied_migrations.map(&:to_i)
      filesystem_migrations = Rails.root.glob(migrations_path).map { |x| File.basename(x).to_i }
      missing_migrations = applied_migrations - filesystem_migrations

      if missing_migrations.any?
        missing_migrations.sort.reverse_each do |migration|
          DB.log_info("Rolling back migration #{migration}...")
          migrator.undo(migration)
        end
      else
        DB.log_info("No migrations found")
        "No migrations found"
      end
    end
  end
end
