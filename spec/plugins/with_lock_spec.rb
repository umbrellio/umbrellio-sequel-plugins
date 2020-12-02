# frozen_string_literal: true

DB.create_table :lock_test_model do
  primary_key :id
  column :count, :integer, default: 0
end

LockModel = Sequel::Model(:lock_test_model)

RSpec.describe "with_lock" do
  let!(:model) { LockModel.create(count: 0) }

  def locks_count
    DB[:pg_locks]
      .join(:pg_stat_activity, Sequel[:pg_locks][:pid] =~ Sequel[:pg_stat_activity][:pid])
      .where(mode: "RowShareLock")
      .where(Sequel[:query] =~ /lock_test_model/) # rubocop:disable Performance/StringInclude
      .count
  end

  it "updates the field" do
    count_before = locks_count

    model.with_lock do
      expect(locks_count).to eq(count_before + 2)
      model.update(count: 1)
    end

    expect(locks_count).to eq(count_before)
    expect(model.count).to eq(1)
  end
end
