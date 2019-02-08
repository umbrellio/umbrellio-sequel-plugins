# frozen_string_literal: true

DB.create_table :currency_rates do
  primary_key :id
  column :currency, :text
  column :period, :tsrange
  column :rates, :jsonb
end

DB.create_table :items do
  primary_key :id
  column :price, :numeric
  column :currency, :text
  column :created_at, :timestamp
end

DB[:currency_rates].insert(
  currency: "EUR",
  period: Sequel.function(:tsrange, Time.now - 60, nil),
  rates: Sequel.pg_jsonb(USD: 1.5),
)

DB[:currency_rates].insert(
  currency: "EUR",
  period: Sequel.function(:tsrange, Time.now - 120, Time.now - 60),
  rates: Sequel.pg_jsonb(USD: 1.3),
)

DB[:items].insert(price: 10, currency: "EUR", created_at: Time.now - 30)
DB[:items].insert(price: 20, currency: "EUR", created_at: Time.now - 70)

RSpec.describe "currency_rates" do
  specify do
    items = DB[:items].with_rates.select(Sequel[:price].in_usd.as(:price)).order(:price)
    expect(items.first).to eq(price: 15)
    expect(items.last).to eq(price: 26)
  end
end
