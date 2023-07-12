# frozen_string_literal: true

namespace :sequel do
  desc "Archive migrations code"
  task archive_migrations: :environment do
    DB.create_table?(:schema_migrations_code) do
      column :version, "numeric", primary_key: true
      column :filename, "text", null: false
      column :code, "text", null: false
    end

    migrations = Rails.root.glob("db/migrate/*.rb").map do |file|
      filename = file.basename.to_s
      { version: filename.to_i, filename: filename, code: file.read }
    end

    conflict_options = {
      target: :version,
      update: { code: Sequel[:excluded][:code] },
    }

    DB[:schema_migrations_code].insert_conflict(**conflict_options).multi_insert(migrations)
  end
end
