# frozen_string_literal: true

DB.create_table :sync_test_model do
  primary_key :id
  column :count, :integer, default: 0
end

SyncModel = Sequel::Model(:sync_test_model)

RSpec.describe "syncronize" do
  let(:model) { SyncModel.create(count: 0) }

  def locks_count
    DB[:pg_locks].where(locktype: "advisory", objid: "1013378621").count
  end

  it "updates the field" do
    count_before = locks_count
    model.synchronize(:model_lock) do |m|
      expect(locks_count).to eq(count_before + 1)
      m.update(count: m.count + 1)
    end
    expect(locks_count).to eq(count_before)
  end
end
