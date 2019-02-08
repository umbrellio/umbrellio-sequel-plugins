# frozen_string_literal: true

# Sequel uses send by default
module Sequel::Plugins::GetColumnValue
  module InstanceMethods
    # Returns a raw column value
    #
    # @example
    #   o = Order::Model.first
    #   o.amount # => #<Money fractional:5000.0 currency:USD>
    #   o.get_column_value(:amount) # => 0.5e2
    # @return value
    def get_column_value(value)
      self[value]
    end
  end
end
