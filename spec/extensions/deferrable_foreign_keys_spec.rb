# frozen_string_literal: true

def create_table_with_foreign_key(name, fk_name, fk_reference, deferrable: true)
  if deferrable
    DB.create_table!(name) { foreign_key fk_name, fk_reference }
  else
    DB.create_table!(name) { foreign_key fk_name, fk_reference, deferrable: false }
  end
end

def alter_table_with_foreign_key(name, fk_name, fk_reference, deferrable: true)
  if deferrable
    DB.alter_table(name) { add_foreign_key fk_name, fk_reference }
  else
    DB.alter_table(name) { add_foreign_key fk_name, fk_reference, deferrable: false }
  end
end

def foreign_keys_deferrable?(*tables)
  tables.all? do |table|
    DB.foreign_key_list(table).all? do |constraint|
      constraint[:deferrable]
    end
  end
end

RSpec.shared_examples "fk constraints deferrable by default" do
  specify do
    expect(foreign_keys_deferrable?(:books, :journals)).to be_truthy
  end
end

RSpec.shared_examples "fk constraints not deferrable" do
  specify do
    expect(foreign_keys_deferrable?(:books)).to be_falsey
    expect(foreign_keys_deferrable?(:journals)).to be_falsey
  end
end

DB.create_table!(:authors) { primary_key :id }
DB.create_table!(:publishers) { primary_key :id }

RSpec.describe "deferrable_foreign_keys" do
  before do
    create_table_with_foreign_key(:books, :author_id, :authors, deferrable: deferrable)
    create_table_with_foreign_key(:journals, :author_id, :authors, deferrable: deferrable)
  end

  let(:deferrable) { true }

  it_behaves_like "fk constraints deferrable by default"

  context "deferrable explicitly denied" do
    let(:deferrable) { false }

    it_behaves_like "fk constraints not deferrable"
  end

  context "when table is altered" do
    before do
      alter_table_with_foreign_key(:books, :publisher_id, :publishers, deferrable: deferrable)
      alter_table_with_foreign_key(:journals, :publisher_id, :publishers, deferrable: deferrable)
    end

    after do
      DB.alter_table(:books) { drop_foreign_key :publisher_id }
      DB.alter_table(:journals) { drop_foreign_key :publisher_id }
    end

    it_behaves_like "fk constraints deferrable by default"

    context "deferrable explicitly denied" do
      let(:deferrable) { false }

      it_behaves_like "fk constraints not deferrable"
    end
  end
end
