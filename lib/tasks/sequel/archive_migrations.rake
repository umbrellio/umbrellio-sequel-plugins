# frozen_string_literal: true

namespace :sequel do
  desc "Archive migrations source code"
  task :archive_migrations,
       [:migrations_path, :migration_table_source] => :environment do |_t, args|
    migrations_path = args[:migrations_path] || "db/migrate/*.rb"
    migration_table_source = args[:migration_table_source] || :schema_migrations_sources

    DB.create_table?(migration_table_source) do
      column :version, "numeric", primary_key: true
      column :filename, "text", null: false
      column :source, "text", null: false
    end

    migrations = Rails.root.glob(migrations_path).map do |file|
      filename = file.basename.to_s
      { version: filename.to_i, filename: filename, source: file.read }
    end

    conflict_options = {
      target: :version,
      update: { filename: Sequel[:excluded][:filename], source: Sequel[:excluded][:source] },
    }

    DB[migration_table_source.to_sym].insert_conflict(**conflict_options).multi_insert(migrations)
  end
end
