# frozen_string_literal: true

require "clickhouse/migrator"

namespace :ch do
  desc "Create a ClickHouse database in the specified cluster"
  task create: :environment do
    CH.create_database(ClickHouse.config.database, cluster: "click_cluster")
  end

  desc "Create a migration tracking table for ClickHouse in PostgreSQL"
  task create_migration_table: :environment do
    DB.create_table Sequel[:public][:clickhouse_migrations] do
      column :filename, :text, null: false, primary_key: true
    end
  end

  desc "Drop the ClickHouse database and truncate the migration tracking table"
  task drop: :environment do
    CH.drop_database(ClickHouse.config.database, cluster: "click_cluster")
    DB.from(Sequel[:public][:clickhouse_migrations]).truncate
    DB.from(Sequel[:public][:clickhouse_migrations_sources]).truncate
  end

  desc "Run migrations for the ClickHouse database"
  task migrate: :environment do
    Rake::Task["sequel:archive_migrations"]
      .invoke("db/migrate/clickhouse/*.rb", "clickhouse_migrations_sources")
    Clickhouse::Migrator.migrate(to: ENV.fetch("VERSION", nil))
  end

  desc "Rollback migrations for the ClickHouse database"
  task rollback: :environment do
    Rake::Task["sequel:rollback_archived_migrations"]
      .invoke("db/migrate/clickhouse/*.rb", "clickhouse_migrations",
              "clickhouse_migrations_sources", "false")
    Clickhouse::Migrator.rollback(to: ENV.fetch("VERSION", nil))
  end

  desc "Reset the ClickHouse database: drop, recreate, and run all migrations"
  task reset: :environment do
    Rake::Task["ch:drop"].invoke
    Rake::Task["ch:create"].invoke
    Rake::Task["ch:migrate"].invoke
  end

  desc "Rollback any missing migrations for ClickHouse"
  task rollback_missing_migrations: :environment do
    Rake::Task["sequel:rollback_missing_migrations"].invoke(:clickhouse_migrations, "false")
  end
end
