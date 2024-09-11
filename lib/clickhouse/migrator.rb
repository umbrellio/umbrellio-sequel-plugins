# frozen_string_literal: true

# :nocov:
module Clickhouse
  module Migrator
    module_function

    def migrate(to: nil)
      if to.present?
        migrator(target: to.to_i).run
      else
        migrator.run
      end
    end

    def rollback(to: nil)
      target = to || migrator.applied_migrations.reverse[1]
      migrator(target: target.to_i).run
    end

    def migrator(**opts)
      Sequel::TimestampMigrator.new(
        DB,
        Rails.root.join("db/migrate/clickhouse"),
        table: :clickhouse_migrations,
        use_transactions: false,
        **opts,
      )
    end
  end
end
# :nocov:
