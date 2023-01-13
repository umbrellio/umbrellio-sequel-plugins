# frozen_string_literal: true

module MigrationDSLExtension
  def transaction_options(opts)
    migration.transaction_opts = opts
  end
end

module SimpleMigrationExtension
  attr_accessor :transaction_opts
end

module MigratorExtension
  def checked_transaction(migration, &block)
    if _use_transaction?(migration)
      _transaction(migration, &block)
    else
      yield
    end
  end

  private

  def _use_transaction?(migration)
    # NOTE: original code
    if @use_transactions.nil?
      if migration.use_transactions.nil?
        @db.supports_transactional_ddl?
      else
        # :nocov:
        migration.use_transactions
        # :nocov:
      end
    else
      # :nocov:
      @use_transactions
      # :nocov:
    end
  end

  def _transaction(migration, &block)
    if migration.transaction_opts.nil?
      db.transaction(&block)
    else
      db.transaction(migration.transaction_opts, &block)
    end
  end
end

Sequel::MigrationDSL.include(MigrationDSLExtension)
Sequel::SimpleMigration.include(SimpleMigrationExtension)
Sequel::Migrator.prepend(MigratorExtension)
