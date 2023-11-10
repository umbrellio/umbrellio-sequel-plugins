# frozen_string_literal: true

namespace :sequel do
  desc "Archive migrations source code"
  task archive_migrations: :environment do
    DB.create_table?(:schema_migrations_sources) do
      column :version, "numeric", primary_key: true
      column :filename, "text", null: false
      column :source, "text", null: false
    end

    migrations = Rails.root.glob("db/migrate/*.rb").map do |file|
      filename = file.basename.to_s
      { version: filename.to_i, filename: filename, source: file.read }
    end

    conflict_options = {
      target: :version,
      update: { filename: Sequel[:excluded][:filename], source: Sequel[:excluded][:source] },
    }

    DB[:schema_migrations_sources].insert_conflict(**conflict_options).multi_insert(migrations)
  end
end
