# frozen_string_literal: true

DB.create_table :event_log
DB.create_table :event_log_1, inherits: :event_log
DB.create_table :event_log_2, inherits: :event_log

RSpec.describe "pg_tools" do
  specify do
    tables = DB.inherited_tables_for(:event_log)
    expect(tables).to eq([:event_log_1, :event_log_2])
  end
end
