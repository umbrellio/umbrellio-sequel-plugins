# frozen_string_literal: true

# Creates encrypted attribute storing
module Sequel::Plugins::AttrEncrypted
  SEPARATOR = "$"
  require "sequel/plugins/attr_encrypted/simple_crypt"

  module ClassMethods
    # Setup attr encrypted
    #
    # @param attrs [Array<Symbol>] column names
    # @param key [String] 32 bytes key
    # @example
    #   Sequel.migration do
    #     change do
    #       alter_table :orders do
    #         add_column :encrypted_first_name, :text
    #         add_column :encrypted_last_name, :text
    #         add_column :encrypted_secret_data, :text
    #       end
    #     end
    #   end
    #
    #   class Order < Sequel::Model
    #     attr_encrypted :first_name, :last_name, key: Settings.private_key
    #     attr_encrypted :secret_data, key: Settings.another_private_key
    #   end

    #   Order.create(first_name: "Ivan")
    #   # => INSERT INTO "orders" ("encrypted_first_name")
    #               VALUES ('/sTi9Q==$OTpuMRq5k8R3JayQ$WjSManQGP9UaZ3C40yDjKg==')
    #
    #   order = Order.create(first_name: "Ivan", last_name: "Smith",
    #                        secret_data: { "some_key" => "Some Value" })
    #   order.reload
    #   order.first_name # => "Ivan"
    #   order.last_name # => "Smith"
    #   order.secret_data # => { "some_key" => "Some Value" }
    def attr_encrypted(*attrs, key:)
      include_encrypted_module!
      attrs.each do |attr|
        define_encrypted_setter(attr, key)
        define_encrypted_getter(attr, key)
        @_encrypted_attributes << attr
      end
    end

    private

    def define_encrypted_setter(attr, key)
      @_attr_encrypted_module.module_eval do
        define_method("#{attr}=") do |value|
          instance_variable_set("@#{attr}", value)

          send("encrypted_#{attr}=", SimpleCrypt.encrypt(value.to_json, key))
        end
      end
    end

    def define_encrypted_getter(attr, key)
      @_attr_encrypted_module.module_eval do
        define_method(attr.to_s) do
          instance_variable_get("@#{attr}") || begin
            decrypted = SimpleCrypt.decrypt(send("encrypted_#{attr}"), key)

            result = !decrypted.nil? ? JSON.parse(decrypted) : decrypted
            instance_variable_set("@#{attr}", result)
          end
        end
      end
    end

    def include_encrypted_module!
      return if defined?(@_attr_encrypted_module)

      @_encrypted_attributes ||= []
      @_attr_encrypted_module = Module.new
      prepend @_attr_encrypted_module
    end
  end

  module InstanceMethods
    def reload
      self.class.instance_variable_get(:@_encrypted_attributes)&.each do |attr|
        instance_variable_set("@#{attr}", nil)
      end

      super
    end
  end
end
