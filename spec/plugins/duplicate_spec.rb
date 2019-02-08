# frozen_string_literal: true

DB.create_table :users do
  primary_key :id
  column :name, :text
end
User = Sequel::Model(:users)

RSpec.describe "duplicate" do
  let(:source) { User.create(name: "John") }

  it "duplicates a model" do
    copy = source.duplicate(name: "James")
    expect(copy).to be_a(User)
    expect(copy.name).to eq("James")
  end
end
