# frozen_string_literal: true

require "securerandom"

RSpec.describe Sequel::Plugins::AttrEncrypted::SimpleCrypt do
  let(:secret_key) { SecureRandom.random_bytes(32) }

  describe ".encrypt" do
    subject(:encrypt) { described_class.encrypt(target, secret_key) }

    context "when passed text is empty" do
      let(:target) { "" }

      it { is_expected.to be_nil }
    end

    context "when passed text is nil" do
      let(:target) { nil }

      it { is_expected.to be_nil }
    end

    context "when passed text is not blank" do
      let(:target) { '{"some_key":"some value"}' }

      it "encrypts text correctly" do
        encrypted = encrypt
        expect(target).to eq(described_class.decrypt(encrypted, secret_key))
      end
    end
  end

  describe ".decrypt" do
    subject(:encrypt) { described_class.decrypt(target, secret_key) }

    context "when passed text is blank" do
      let(:target) { "" }

      it { is_expected.to be_nil }
    end

    context "when passed text is nil" do
      let(:target) { nil }

      it { is_expected.to be_nil }
    end
  end
end
