# frozen_string_literal: true

DB.create_table(:test_orders) do
  column :amount, "numeric"
  column :currency, "text"
  column :billing_amount, "float"
  column :billing_currency, "text"
end

RSpec.describe Sequel::Plugins::MoneyAccessors do
  let(:order_model) do
    Class.new(Sequel::Model(:test_orders)) do
      money_accessor :amount, :currency
      money_accessor :billing_amount, :billing_currency
    end
  end

  let(:order) { order_model.create(amount: Money.from_amount(15, "USD")) }

  it "stores column as Money instance" do
    expect(order.amount).to eq(Money.new(1500, "USD"))
    expect(order.billing_amount).to eq(nil)

    expect(order.values).to eq(
      amount: 15,
      currency: "USD",
      billing_amount: nil,
      billing_currency: nil,
    )
  end

  it "allows setting amount to nil" do
    order.set(amount: nil, billing_amount: Money.from_amount(25, "EUR"))

    expect(order.amount).to eq(nil)
    expect(order.billing_amount).to eq(Money.new(2500, "EUR"))

    expect(order.values).to eq(
      amount: nil,
      currency: nil,
      billing_amount: 25,
      billing_currency: "EUR",
    )
  end

  context "invalid value provided to setter" do
    it "raises error" do
      expect { order_model.new(amount: 15) }.to raise_error(
        Sequel::Plugins::MoneyAccessors::MoneyClassRequired,
        "amount value must be either Money instance or nil",
      )
    end
  end
end
