# frozen_string_literal: true

DB.create_table :test

RSpec.describe "slave" do
  specify do
    dataset = DB[:test]
    slave = dataset.slave
    expect(dataset).not_to eq(slave)
    expect(slave).to be_server(:slave)
  end
end
