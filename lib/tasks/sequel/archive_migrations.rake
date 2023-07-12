# frozen_string_literal: true

namespace :sequel do
  desc "Archive migrations code"
  task archive_migrations: :environment do
    DB.create_table?(:schema_migrations_code) do
      column :version, "numeric", primary_key: true
      column :code, "text"
    end

    migrations = []

    Rails.root.glob("db/migrate/*.rb").each do |file|
      migrations << { version: file.basename.to_s.to_i, code: file.read }
    end

    conflict_options = {
      target: :version,
      update: { code: Sequel[:excluded][:code] },
    }

    DB[:schema_migrations_code].insert_conflict(**conflict_options).multi_insert(migrations)
  end
end
