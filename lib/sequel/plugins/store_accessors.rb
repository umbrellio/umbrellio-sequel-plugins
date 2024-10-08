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

    def call(_)
      super.tap(&:calculate_initial_store)
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
        define_method(:"#{field}=") do |value|
          send(:"#{column}=", send(column).to_h.merge(field.to_s => value))
        end
      end
    end
  end

  module InstanceMethods
    def after_update
      super
      refresh_initial_store
    end

    def after_create
      super
      refresh_initial_store
    end

    def calculate_initial_store
      @store_values_hashes || refresh_initial_store
    end

    def changed_columns
      changed = super
      return changed unless respond_to?(:store_columns)
      changed = changed.dup if frozen?
      store_columns.each do |col|
        match = patched(col).empty? && deleted(col).empty?
        if changed.include?(col)
          changed.delete(col) if match
        else
          changed << col unless match
        end
      end
      changed
    end

    private

    def _update_without_checking(columns)
      return super unless respond_to?(:store_columns)

      mapped_columns = columns.to_h do |column, v|
        next [column, v] unless store_columns.include?(column)

        json = Sequel.pg_jsonb_op(
          Sequel.function(:coalesce, Sequel[column], Sequel.pg_jsonb({})),
        )
        updated = deleted(column).inject(json) { |res, k| res.delete_path([k.to_s]) }
        [column, updated.concat(patched(column))]
      end

      super(mapped_columns)
    end

    def patched(column)
      initial_fields = initial_store_fields[column] || []
      initial_hashes = store_values_hashes[column] || {}
      current = @values[column] || {}

      current.dup.delete_if do |k, v|
        initial_fields.include?(k) && initial_hashes[k] == v.hash
      end
    end

    def deleted(column)
      initial_fields = initial_store_fields[column] || []
      current = @values[column] || {}

      initial_fields.dup - current.keys
    end

    def _refresh(dataset)
      super
      refresh_initial_store
    end

    def _save_refresh
      super
      refresh_initial_store
    end

    def refresh_initial_store
      return unless respond_to?(:store_columns)
      store_values = @values.slice(*store_columns)
      @initial_store_fields = store_values.transform_values { |v| v.to_h.keys }
      @store_values_hashes = store_values.transform_values { |v| v.to_h.transform_values(&:hash) }
    end

    def initial_store_fields
      @initial_store_fields || {}
    end

    def store_values_hashes
      @store_values_hashes || {}
    end
  end
end
