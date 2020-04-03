# frozen_string_literal: true

require "money"

# Creates accessors for money values
module Sequel::Plugins::MoneyAccessors
  MoneyClassRequired = Class.new(StandardError)

  module ClassMethods
    # Setup money accessor
    #
    # @param amount_column [Symbol] amount column
    # @param currency_column [Symbol] currency column
    # @example
    #   class Order < Sequel::Model
    #     money_accessor :amount, :currency
    #   end
    #
    #   order = Order.create(amount: 200, currency: "EUR")
    #   order.amount # => #<Money fractional:20000.0 currency:RUB>
    #   order.currency # => "EUR"
    def money_accessor(amount_column, currency_column)
      money_getter(amount_column, currency_column)
      money_setter(amount_column, currency_column)
    end

    def money_getter(amount_column, currency_column)
      include_accessors_module!
      @_money_accessors_module.module_eval do
        define_method(amount_column) do
          amount, currency = super(), send(currency_column)
          return unless amount && currency
          Money[amount.to_d, currency]
        end
      end
    end

    def money_setter(amount_column, currency_column)
      include_accessors_module!
      @_money_accessors_module.module_eval do
        define_method("#{amount_column}=") do |value|
          case value
          when Money
            amount = value.to_d
            currency = value.currency.to_s
          when nil
            amount = currency = nil
          else
            raise MoneyClassRequired, "#{amount_column} value must be either Money instance or nil"
          end

          super(amount)
          send("#{currency_column}=", currency)
        end
      end
    end

    private

    def include_accessors_module!
      return if defined?(@_money_accessors_module)
      @_money_accessors_module = Module.new
      prepend @_money_accessors_module
    end
  end
end
