# frozen_string_literal: true

DB.create_table :posts do
  column :metadata, :jsonb, default: "{}"
end

class Post < Sequel::Model(:posts)
  store :metadata, :tags
end

RSpec.describe "store_accessors" do
  let(:post) { Post.create(tags: %w[first second]) }

  it "stores tags as json" do
    expect(post.metadata).to eq("tags" => %w[first second])
    expect(post.tags).to eq(%w[first second])
  end
end
