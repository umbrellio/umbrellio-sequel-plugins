# frozen_string_literal: true

DB.create_table(:encrypted_orders) do
  primary_key :id
  column :encrypted_name, :text
  column :encrypted_secret_data, :text
end

RSpec.describe Sequel::Plugins::AttrEncrypted do
  subject(:order) { order_model.create(name: name, secret_data: secret_data) }

  let(:name) { "Ivan" }
  let(:secret_data) { { "some_key" => "Some Value" } }
  let(:order_model) do
    Class.new(Sequel::Model(:encrypted_orders)) do
      attr_encrypted :name, key: "The best 32bytes secret key ever"
      attr_encrypted :secret_data, key: "Another 32 bytes secret key ever"
    end
  end
  let(:secret_attrs) { %i[name secret_data] }

  it "stores only encrypted attributes" do
    secret_attrs.each { |attr| expect(order[attr]).to be(nil) }
    secret_attrs.each { |attr| expect(order[:"encrypted_#{attr}"]).not_to be_empty }
  end

  it "encrypts and decrypts attributes correctly" do
    secret_attrs.each { |attr| expect(order.public_send(attr)).to eq(public_send(attr)) }
  end

  context "when it was passed nil value as an attribute" do
    let(:name) { nil }
    let(:secret_data) { nil }

    it "stores it correctly" do
      expect(order.name).to eq(nil)
      expect(order.secret_data).to eq(nil)
    end
  end

  context "when it was passed empty value as an attribute" do
    let(:name) { "" }
    let(:secret_data) { "" }

    it "stores as nil" do
      expect(order.name).to eq("")
      expect(order.secret_data).to eq("")
    end
  end
end
