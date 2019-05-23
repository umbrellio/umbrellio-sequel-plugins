# frozen_string_literal: true

# NOTE: extension has its own specs in its repo, here we just make sure it's loadable
# https://github.com/umbrellio/sequel-connection_guard

RSpec.describe "connection_guard extension" do
  it "can be loaded" do
    Sequel.extension :connection_guard

    expect(Sequel::DatabaseGuard).not_to be_nil
  end
end
