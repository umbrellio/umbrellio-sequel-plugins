# frozen_string_literal: true

DB.create_table :posts do
  primary_key :id
  column :data, :jsonb, default: "{}"
  column :metadata, :jsonb, default: "{}"
end

class Post < Sequel::Model(:posts)
  store :data, :amount, :project_id
  store :metadata, :tags, :marker
end

RSpec.describe "store_accessors" do
  let!(:post) { Post.create(tags: %w[first second], amount: 10) }

  it "stores tags as json" do
    expect(post.amount).to eq(10)
    expect(post.data).to eq("amount" => 10)
    expect(post.tags).to eq(%w[first second])
    expect(post.metadata).to eq("tags" => %w[first second])
  end

  it "safely updates" do
    first_post = Post[post.id]
    first_post.marker = true
    first_post.project_id = 1
    first_post.save_changes
    post.tags = %w[first]
    post.amount = 5
    post.save_changes
    expect(post.reload.tags).to eq(%w[first])
    expect(post.marker).to eq(true)
    expect(post.amount).to eq(5)
    expect(post.project_id).to eq(1)
  end
end
