# frozen_string_literal: true

# Sequel analog for `ActiveRecord::Base#dup` method
module Sequel::Plugins::Duplicate
  module ClassMethods
    # Returns a copy of current model
    #
    # @param model [Sequel::Model] source object
    # @param new_attrs [Hash] attributes to override
    #
    # @return [Sequel::Model]
    def duplicate(model, **new_attrs)
      pk = *primary_key
      attrs = model.values.reject { |key, *| pk.include?(key) }
      new(**attrs, **new_attrs)
    end
  end

  module InstanceMethods
    # Returns a copy of current model
    #
    # @param new_attrs [Hash] attributes to override
    #
    # @return [Sequel::Model]
    def duplicate(**new_attrs)
      self.class.duplicate(self, **new_attrs)
    end
  end
end
