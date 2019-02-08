# frozen_string_literal: true

require "rake"

RSpec.describe "timestamp_migrator_undo_extension" do
  def create_migrator
    Sequel::TimestampMigrator.new(DB, "spec/files/migrations")
  end

  before { create_migrator.run }

  specify do
    expect(DB.tables).to include(:first_table, :second_table)
    create_migrator.undo(1549624163)
    expect(DB.tables).not_to include(:first_table)
  end
end
