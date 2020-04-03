# frozen_string_literal: true

require "logger"

# rubocop:disable Layout/ClassStructure
module Sequel
  class TimestampMigrator
    # Rollback a migration
    def undo(version)
      path = files.find { |file| migration_version_from_file(get_filename(file)) == version }
      raise "Migration #{version} does not exist in the filesystem" unless path

      filename = get_filename(path)
      raise "Migration #{version} is not applied" unless applied_migrations.include?(filename)

      migration = get_migration(path)

      time = Time.now
      db.log_info("Undoing migration #{filename}")

      checked_transaction(migration) do
        migration.apply(db, :down)
        ds.filter(column => filename).delete
      end

      elapsed = format("%<time>0.6f", time: Tim.now - time)
      db.log_info("Finished undoing migration #{filename}, took #{elapsed} seconds")
    end

    module TimestampMigratorLogger
      # Setup the logger
      def run
        db.loggers << Logger.new($stdout, level: :info)
        level = db.sql_log_level
        db.sql_log_level = :debug
        db.log_info("Begin applying migrations")
        super
      ensure
        db.sql_log_level = level
        db.loggers.pop
      end
    end

    Sequel::TimestampMigrator.prepend TimestampMigratorLogger

    private

    def get_migration(path)
      migration = load_migration_file(path)

      return migration if Gem::Version.new(Sequel.version) >= Gem::Version.new("5.6")
      # :nocov:
      Migration.descendants.last
      # :nocov:
    end

    def get_filename(path)
      File.basename(path).downcase
    end
  end
end
# rubocop:enable Layout/ClassStructure
