# frozen_string_literal: true

module Sequel
  # Extension with some tools that use pg internal tables and views
  module PGTools
    # List inherited tables for specific parent table
    #
    # @param table_name [String, Symbol] name of the parent table
    # @param schema [String, Symbol] schema of the parent table, defaults to +:public+
    #
    # @example
    #   DB.inherited_tables_for(:event_log)
    #   # => [:event_log_2019_01, :event_log_2019_02]
    #
    #   DB.inherited_tables_for(:event_log, schema: :foo)
    #   # => []
    # @return [Array<Symbol>] list of inhertied tables
    def inherited_tables_for(table_name, schema: :public)
      self[:pg_inherits]
        .select(Sequel[:cn][:nspname].as(:schema), Sequel[:c][:relname].as(:child))
        .left_join(Sequel[:pg_class].as(:c), Sequel[:inhrelid] => Sequel[:c][:oid])
        .left_join(Sequel[:pg_class].as(:p), Sequel[:inhparent] => Sequel[:p][:oid])
        .left_join(Sequel[:pg_namespace].as(:pn), Sequel[:pn][:oid] => Sequel[:p][:relnamespace])
        .left_join(Sequel[:pg_namespace].as(:cn), Sequel[:cn][:oid] => Sequel[:c][:relnamespace])
        .where(Sequel[:p][:relname] => table_name.to_s, Sequel[:pn][:nspname] => schema.to_s)
        .to_a
        .map { |x| x[:child].to_sym }
    end
  end

  Database.register_extension(:pg_tools, PGTools)
end
