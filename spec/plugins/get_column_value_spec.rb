# frozen_string_literal: true

DB.create_table :links do
  column :link, :text
  column :title, :text
end

class Link < Sequel::Model(:links)
  def link
    Struct.new(:url, :title).new(super, title)
  end
end

RSpec.describe "duplicate" do
  let(:entry) { Link.create(link: "https://google.com", title: "Goole") }

  it "returns a column value" do
    expect(entry.link).to be_a(Struct)
    expect(entry.get_column_value(:link)).to eq("https://google.com")
  end
end
