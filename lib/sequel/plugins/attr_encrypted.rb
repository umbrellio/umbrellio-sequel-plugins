# frozen_string_literal: true

require "base64"

# Creates encrypted attribute storing
module Sequel::Plugins::AttrEncrypted
  SEPARATOR = "$"

  module ClassMethods
    # Setup attr encrypted
    #
    # @param attrs [Array<Symbol>] column names
    # @param key [String] 32 bytes key
    # @param json [Boolean] store attribute as json or not
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
    #     attr_encrypted :secret_data, key: Settings.another_private_key, json: true
    #   end
    #
    #   order = Order.create(first_name: "Ivan", last_name: "Smith",
    #                        secret_data: { "some_key" => "Some Value" })
    #   order.reload
    #   order.first_name # => "Ivan"
    #   order.secret_data # => { "some_key" => "Some Value" }
    def attr_encrypted(*attrs, key:, json: false)
      include_encrypted_module!
      attrs.each do |attr|
        define_encrypted_setter(attr, key, json)
        define_encrypted_getter(attr, key, json)
      end
    end

    private

    def define_encrypted_setter(attr, key, json)
      @_attr_encrypted_module.module_eval do
        define_method("#{attr}=") do |value|
          instance_variable_set("@#{attr}", value)

          send("encrypted_#{attr}=", encrypt(json ? value.to_json : value, key))
        end
      end
    end

    def define_encrypted_getter(attr, key, json)
      @_attr_encrypted_module.module_eval do
        define_method(attr.to_s) do
          instance_variable_get("@#{attr}") || begin
            decrypted = decrypt(send("encrypted_#{attr}"), key)

            result = json && !decrypted.nil? ? JSON.parse(decrypted) : decrypted
            instance_variable_set("@#{attr}", result)
          end
        end
      end
    end

    def include_encrypted_module!
      return if defined?(@_attr_encrypted_module)

      @_attr_encrypted_module = Module.new
      prepend @_attr_encrypted_module
    end
  end

  module InstanceMethods
    private

    def encrypt(string, key)
      return unless string.is_a?(String) && !string.empty?

      encryptor = new_cipher
      encryptor.encrypt
      encryptor.key = key
      iv = encryptor.random_iv

      encrypted = encryptor.update(string) + encryptor.final
      dump(encrypted, iv, encryptor.auth_tag)
    end

    def decrypt(string, key)
      encrypted, iv, auth_tag = parse(string) if string.is_a?(String)
      return if [encrypted, iv, auth_tag].any?(&:nil?)

      decryptor = new_cipher
      decryptor.decrypt
      decryptor.key = key
      decryptor.iv = iv
      decryptor.auth_tag = auth_tag

      decryptor.update(encrypted) + decryptor.final
    end

    def new_cipher
      OpenSSL::Cipher::AES256.new(:gcm)
    end

    def parse(string)
      string.split(SEPARATOR).map { |x| Base64.strict_decode64(x) }
    end

    def dump(*values)
      [*values].map { |x| Base64.strict_encode64(x) }.join(SEPARATOR)
    end
  end
end
