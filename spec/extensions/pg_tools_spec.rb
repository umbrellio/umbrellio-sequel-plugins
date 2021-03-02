# frozen_string_literal: true

DB.create_table :event_log
DB.create_table :event_log1, inherits: :event_log
DB.create_table :event_log2, inherits: :event_log

RSpec.describe "pg_tools" do
  specify do
    tables = DB.inherited_tables_for(:event_log)
    expect(tables).to eq([:event_log1, :event_log2])
  end
end
