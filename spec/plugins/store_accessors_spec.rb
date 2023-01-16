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

  it "updates only changed" do
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

  it "deletes fields" do
    post.update(data: {}, metadata: {})
    expect(post.reload.data).to eq({})
    expect(post.metadata).to eq({})
    expect(post.tags).to eq(nil)
    expect(post.amount).to eq(nil)
  end

  it "directly updates right" do
    post.update(
      data: { amount: 1, project_id: 2 },
      metadata: { tags: %w[first], marker: true },
    )
    expect(post.reload.data.to_h).to eq("amount" => 1, "project_id" => 2)
    expect(post.metadata.to_h).to eq("tags" => %w[first], "marker" => true)
    expect(post.amount).to eq(1)
    expect(post.project_id).to eq(2)
    expect(post.tags).to eq(%w[first])
    expect(post.marker).to eq(true)
  end

  it "updates fields" do
    post.update(tags: %w[first])
    expect(post.reload.metadata.to_h).to eq("tags" => %w[first])
    expect(post.tags).to eq(%w[first])
  end

  it "updates on mutate fields" do
    post.tags.push("third")
    post.save_changes
    expect(post.reload.metadata.to_h).to eq("tags" => %w[first second third])
    expect(post.tags).to eq(%w[first second third])
  end

  it "updates on mutate store" do
    post.metadata[:marker] = true
    post.save_changes
    expect(post.reload.metadata.to_h).to eq("tags" => %w[first second], "marker" => true)
    expect(post.tags).to eq(%w[first second])
    expect(post.marker).to eq(true)
  end

  it "updates from nil" do
    post.update(data: nil)
    post.amount = 20
    post.save_changes
    expect(post.reload.data).to eq("amount" => 20)
    expect(post.amount).to eq(20)
  end
end
