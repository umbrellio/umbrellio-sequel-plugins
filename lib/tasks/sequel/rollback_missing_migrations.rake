# frozen_string_literal: true

require "sequel/timestamp_migrator_undo_extension"

namespace :sequel do
  desc "Rollback migrations that are absent in revision when deploying on staging"
  task :rollback_missing_migrations, [:table, :use_transactions] => :environment do |_t, args|
    use_transactions = args[:use_transactions].nil? ? nil : args[:use_transactions] == "true"

    extract_migrations = lambda do |path|
      Dir.glob("#{path}/db/migrate/*.rb").map { |filename| File.basename(filename).to_i }
    end

    old_migrations = extract_migrations.call(ENV.fetch("OLD_RELEASE"))
    new_migrations = extract_migrations.call(ENV.fetch("NEW_RELEASE"))
    migrations_to_rollback = old_migrations - new_migrations

    next if migrations_to_rollback.empty?

    puts "Rolling back migrations:"
    puts migrations_to_rollback

    path = Rails.root.join("db/migrate")
    migrator_args = {
      table: args[:table],
      use_transactions: use_transactions,
      allow_missing_migration_files: false,
    }.compact
    migrator = Sequel::TimestampMigrator.new(DB, path, migrator_args)
    applied_migrations = migrator.applied_migrations.map(&:to_i)
    migrations = applied_migrations.select { |m| m.in?(migrations_to_rollback) }.sort.reverse

    migrations.each { |migration| migrator.undo(migration) }
  end
end
