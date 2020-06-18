# frozen_string_literal: true

DB.create_table(:encrypted_orders) do
  primary_key :id
  column :encrypted_first_name, :text
  column :encrypted_last_name, :text
  column :encrypted_secret_data, :text
end

RSpec.describe Sequel::Plugins::AttrEncrypted do
  subject(:order) do
    order_model.create(first_name: first_name, last_name: last_name, secret_data: secret_data)
  end

  let(:first_name) { "Ivan" }
  let(:last_name) { "Smith" }
  let(:secret_data) { { "some_key" => "Some Value" } }
  let(:order_model) do
    Class.new(Sequel::Model(:encrypted_orders)) do
      attr_encrypted :first_name, :last_name, key: "The best 32bytes secret key ever"
      attr_encrypted :secret_data, key: "Another 32 bytes secret key ever", json: true
    end
  end
  let(:secret_attrs) { %i[first_name last_name secret_data] }

  it "stores only encrypted attributes" do
    order.reload
    secret_attrs.each { |attr| expect(order[attr]).to be(nil) }
    secret_attrs.each { |attr| expect(order[:"encrypted_#{attr}"]).not_to be_empty }
  end

  it "encrypts and decrypts attributes correctly" do
    order.reload
    secret_attrs.each { |attr| expect(order.public_send(attr)).to eq(public_send(attr)) }
  end

  context "when it was passed nil value as an attribute" do
    let(:first_name) { nil }
    let(:secret_data) { nil }

    it "stores it correctly" do
      order.reload
      expect(order.first_name).to eq(nil)
      expect(order.secret_data).to eq(nil)
    end
  end

  context "when it was passed empty value as an attribute" do
    let(:first_name) { "" }
    let(:secret_data) { "" }

    it "stores it correctly" do
      order.reload
      expect(order.reload.first_name).to eq("")
      expect(order.secret_data).to eq("")
    end
  end
end
