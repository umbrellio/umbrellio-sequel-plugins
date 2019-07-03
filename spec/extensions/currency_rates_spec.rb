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
  column :updated_at, :timestamp
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

DB[:items].insert(price: 10, currency: "EUR", created_at: Time.now - 30, updated_at: Time.now)
DB[:items].insert(price: 20, currency: "EUR", created_at: Time.now - 70, updated_at: Time.now)

RSpec.describe "currency_rates" do
  let(:items) do
    DB[:items].with_rates(*args).select(Sequel[:price].in_usd.as(:price)).order(:price)
  end

  let(:args) { [] }

  specify do
    expect(items.first).to eq(price: 15)
    expect(items.last).to eq(price: 26)
  end

  context "with symbol in time_column param" do
    let(:args) { [time_column: :updated_at] }

    specify do
      expect(items.first).to eq(price: 15)
      expect(items.last).to eq(price: 30)
    end
  end

  context "with expression in time_column param" do
    let(:args) { [time_column: Sequel[:items][:updated_at]] }

    specify do
      expect(items.first).to eq(price: 15)
      expect(items.last).to eq(price: 30)
    end
  end
end
