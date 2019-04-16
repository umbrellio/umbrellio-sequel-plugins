# frozen_string_literal: true

DB.create_table :sync_test do
  column :count, :integer, default: 0
end

DB[:sync_test].insert(count: 0)

RSpec.describe "syncronize" do
  def locks_count
    DB[:pg_locks].where(locktype: "advisory", objid: "315964566").count
  end

  def update!
    DB.synchronize_with(:increase_lock) do
      prev_count = DB[:sync_test].first[:count]
      sleep 1
      DB[:sync_test].update(count: prev_count + 1)
    end
  end

  it "updates the field" do
    threads = []
    threads << Thread.new { update! }
    threads << Thread.new { update! }
    threads.each(&:join)
    expect(DB[:sync_test].first[:count]).to eq(2)
  end
end
