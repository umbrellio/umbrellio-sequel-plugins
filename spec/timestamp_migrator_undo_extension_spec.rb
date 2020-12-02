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

  context "with missing migration" do
    it "raises proper error" do
      expect { create_migrator.undo(20201202130630) }.to raise_error(
        Sequel::Migrator::Error, "Migration 20201202130630 does not exist in the filesystem"
      )
    end
  end
end
