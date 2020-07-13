# frozen_string_literal: true

module Sequel
  module CreateTableDefaultDeferrable
    def foreign_key(name, table = nil, opts = nil)
      deferrable = ::Umbrellio::SequelPlugins["extensions.deferrable_foreign_keys.by_default"]
      patch = { deferrable: deferrable }
      opts = opts.nil? ? patch : patch.merge(opts)
      super(name, table, opts)
    end
  end

  module AlterTableDefaultDeferrable
    def add_foreign_key(name, table, opts = nil)
      deferrable = ::Umbrellio::SequelPlugins["extensions.deferrable_foreign_keys.by_default"]
      patch = { deferrable: deferrable }
      opts = opts.nil? ? patch : patch.merge(opts)
      super(name, table, opts)
    end
  end
end

Sequel::Schema::CreateTableGenerator.prepend(Sequel::CreateTableDefaultDeferrable)
Sequel::Schema::AlterTableGenerator.prepend(Sequel::AlterTableDefaultDeferrable)
