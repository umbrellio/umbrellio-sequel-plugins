# frozen_string_literal: true

module Sequel::Plugins::AttrEncrypted::SimpleCrypt
  extend self
  require "base64"

  SEPARATOR = "$"

  def encrypt(string, key)
    return unless string.is_a?(String) && !string.empty?

    encryptor = new_cipher(key, &:encrypt)
    iv = encryptor.random_iv

    encrypted = encryptor.update(string) + encryptor.final
    dump(encrypted, iv, encryptor.auth_tag)
  end

  def decrypt(string, key)
    encrypted, iv, auth_tag = parse(string) if string.is_a?(String)
    return if [encrypted, iv, auth_tag].any?(&:nil?)

    decryptor = new_cipher(key, &:decrypt)
    decryptor.iv = iv
    decryptor.auth_tag = auth_tag

    decryptor.update(encrypted) + decryptor.final
  end

  private

  def new_cipher(key)
    result = OpenSSL::Cipher.new("aes-256-gcm")
    yield(result)
    result.key = key
    result
  end

  def parse(string)
    string.split(SEPARATOR).map { |x| Base64.strict_decode64(x) }
  end

  def dump(*values)
    Array(values).map { |x| Base64.strict_encode64(x) }.join(SEPARATOR)
  end
end
