# frozen_string_literal: true

# Creates accessors for json values
module Sequel::Plugins::StoreAccessors
  module ClassMethods
    # Setup a store
    #
    # @param column [Symbol] jsonb column
    # @param fields [Array<Symbol>] keys in json, which will be accessors
    # @example
    #   class User < Sequel::Model
    #      store :data, :first_name
    #   end
    #
    #   user = User.create(first_name: "John")
    #   user.first_name # => "John"
    #   user.data # => {"first_name": "John"}
    def store(column, *fields)
      include_accessors_module(column)

      fields.each do |field|
        define_store_getter(column, field)
        define_store_setter(column, field)
      end
    end

    private

    def include_accessors_module(column)
      unless defined?(@_store_accessors_module)
        @_store_accessors_module = Module.new
        include @_store_accessors_module
      end

      prev_columns = @_store_accessors_module.instance_variable_get(:@_store_columns) || []
      new_columns = [*prev_columns, column]
      @_store_accessors_module.instance_variable_set(:@_store_columns, new_columns)
      @_store_accessors_module.define_method(:store_columns) { new_columns }
    end

    def define_store_getter(column, field)
      @_store_accessors_module.module_eval do
        define_method(field) do
          send(column).to_h[field.to_s]
        end
      end
    end

    def define_store_setter(column, field)
      @_store_accessors_module.module_eval do
        define_method("#{field}=") do |value|
          send("#{column}=", send(column).to_h.merge(field.to_s => value))
        end
      end
    end
  end

  module InstanceMethods
    def before_update
      super
      return unless respond_to?(:store_columns)
      @_stores_current_values = {}
      send(:store_columns).each do |store_column|
        current = send(store_column)
        @_stores_current_values[store_column] = current
        next unless changed_columns.include?(store_column)

        initial = initial_value(store_column)
        patch = current.dup.delete_if { |k, v| initial.key?(k) && initial[k] == v }
        deleted = initial.dup.delete_if { |k, _| current.key?(k) }

        json = Sequel.pg_jsonb_op(Sequel.function(
            :coalesce,
            Sequel[store_column],
            Sequel.pg_jsonb({}),
          ),
        )
        updated = deleted.inject(json) { |res, (k, _)| res.delete_path([k.to_s]) }
        updated = updated.concat(patch)
        send("#{store_column}=", updated)
      end
    end

    def after_update
      super
      return unless respond_to?(:store_columns)
      send(:store_columns).each { |c| send("#{c}=", @_stores_current_values[c]) }
      @_stores_current_values = {}
    end
  end
end
