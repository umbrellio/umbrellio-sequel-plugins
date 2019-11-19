# frozen_string_literal: true

module Sequel
  module CreateTableDefaultDeferrable
    def foreign_key(name, table = nil, opts = nil)
      patch = { deferrable: true }
      opts = opts.nil? ? patch : patch.merge(opts)
      super(name, table, opts)
    end
  end

  module AlterTableDefaultDeferrable
    def add_foreign_key(name, table, opts = nil)
      patch = { deferrable: true }
      opts = opts.nil? ? patch : patch.merge(opts)
      super(name, table, opts)
    end
  end
end

Sequel::Schema::CreateTableGenerator.prepend(Sequel::CreateTableDefaultDeferrable)
Sequel::Schema::AlterTableGenerator.prepend(Sequel::AlterTableDefaultDeferrable)
