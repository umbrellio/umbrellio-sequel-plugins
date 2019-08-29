# frozen_string_literal: true

module Sequel::Plugins::Upsert
  module ClassMethods
    # Returns an upsert dataset
    #
    # @param target [Symbol] target column
    # @example
    #   User.upsert_dataset.insert(name: "John", email: "jd@test.com")
    #
    # @return [Sequel::Dataset] dataset
    def upsert_dataset(target: primary_key)
      cols = columns - Array(primary_key)

      update_spec = cols.map { |x| [x, Sequel[:excluded][x]] }
      where_spec = cols.map { |x| Sequel::Plugins::Upsert.distinct_expr(table_name, x) }.reduce(:|)

      dataset.insert_conflict(
        target: target,
        update: update_spec,
        update_where: where_spec,
      )
    end

    # Executes the upsert request
    #
    # @param row [Hash] values
    # @param options [Hash] options
    #
    # @example
    #   User.upsert(name: "John", email: "jd@test.com", target: :email)
    # @return [Sequel::Model]
    def upsert(row, **options)
      upsert_dataset(**options).insert(sequel_values(row))
    end

    # Executes the upsert request for multiple rows
    # @see #upsert
    # @see #upsert_dataset
    def multi_upsert(rows, **options)
      rows = rows.map { |row| sequel_values(row) }
      upsert_dataset(options).multi_insert(rows)
    end

    # Returns formatted row values
    #
    # @param row [Hash]
    #
    # @return [Hash]
    def sequel_values(row)
      upsert_model.new(row).values
    end

    # Returns upsert model for current table
    #
    # @return [Sequel::Model]
    def upsert_model
      @upsert_model ||= Sequel::Model(table_name)
    end
  end

  def self.distinct_expr(table_name, col)
    Sequel.lit("? IS DISTINCT FROM ?", Sequel[table_name][col], Sequel[:excluded][col])
  end
end
