# frozen_string_literal: true

RSpec.describe "migration_transaction_options" do
  def migrator
    Sequel::TimestampMigrator.new(DB, "spec/files/migrations")
  end

  before { migrator.run }

  it "does not migrate since rollback always option is set" do
    expect(DB.tables).to include(:first_table, :second_table)
    expect(DB.tables).not_to include(:third_table)
  end
end
