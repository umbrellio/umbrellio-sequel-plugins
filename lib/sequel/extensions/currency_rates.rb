# frozen_string_literal: true

module Sequel
  # Extension for currency-conversion via currency_rates table
  module CurrencyRates
    # Join a rates table
    #
    # @param aliaz [Symbol] alias to be used for joined table
    # @param table [Symbol] table name to join to
    # @param currency_column [Symbol or Sequel::SQL::Expression] currency column by which
    #   table is joined
    # @param time_column [Symbol or Sequel::SQL::Expression] time column by which table is joined
    #
    # @example
    #   Order::Model.with_rates.select(Sequel[:amount].in_usd)
    # @return [Sequel::Dataset] dataset
    def with_rates(
      aliaz = :currency_rates,
      table: table_name,
      rates_table: Sequel[:currency_rates],
      currency_column: :currency,
      time_column: :created_at
    )
      table = Sequel[table]
      rates = Sequel[aliaz]

      currency_expr = wrap_if_symbol(currency_column, table)
      time_expr = wrap_if_symbol(time_column, table)

      join_expr = (rates[:currency] =~ currency_expr) & rates[:period].pg_range.contains(time_expr)
      left_join(rates_table.as(aliaz), join_expr)
    end

    # Returns a table name
    #
    # @return [Symbol] table name
    def table_name
      respond_to?(:first_source_alias) ? first_source_alias : super
    end

    private

    def wrap_if_symbol(column_name, table)
      column_name.is_a?(Symbol) ? table[column_name] : column_name
    end
  end

  module CurrencyRateExchange
    # Exchange column value to a specific currency
    #
    # @param currency [String] currency
    # @param rates_table [Symbol] rates table name
    # @param rates_column [Symbol] rates column name
    #
    # @example
    #   Sequel[:amount].exchange_to("EUR", :order_rates, :courses)
    # @return [Sequel::SQL::NumericExpression]
    def exchange_to(currency, rates_table = :currency_rates, rates_column = :rates)
      rate = Sequel[rates_table][rates_column].pg_jsonb.get_text(currency).cast_numeric(Float)
      self * rate
    end

    # Exchange column value to usd
    #
    # @param opts (see #exchange_to)
    #
    # @example
    #   Sequel[:amount].in_usd
    # @return (see #exchange_to)
    def in_usd(*opts)
      exchange_to("USD", *opts)
    end
  end

  Model.extend(CurrencyRates)
  SQL::GenericExpression.include(CurrencyRateExchange)
  Dataset.register_extension(:currency_rates, CurrencyRates)
end
