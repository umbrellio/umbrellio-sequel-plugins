# frozen_string_literal: true

DB.create_table :upsert_test do
  column :name, :text
  column :value, :integer
  index :name, unique: true
end

UpsertModel = Sequel::Model(:upsert_test)
UpsertModel.create(name: "name", value: 1)
UpsertModel.create(name: "name2", value: 3)

RSpec.describe "upsert" do
  it "updates existing record" do
    UpsertModel.upsert({ name: "name", value: 2 }, target: :name)
    expect(UpsertModel[name: "name"].value).to eq(2)
  end

  describe "multi_upsert" do
    it "updates multiple rows" do
      data = [{ name: "name", value: 10 }, { name: "name2", value: 20 }]
      UpsertModel.multi_upsert(data, target: :name)
      expect(UpsertModel.count).to eq(2)
      expect(UpsertModel[name: "name"].value).to eq(10)
      expect(UpsertModel[name: "name2"].value).to eq(20)
    end
  end
end
