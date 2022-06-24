# frozen_string_literal: true

RSpec.describe "set_local" do
  def run!
    DB.transaction(set_local: { statement_timeout: "1s" }) do
      DB.execute("SELECT pg_sleep(2)")
    end
  end

  specify do
    expect { run! }.to raise_error(/canceling statement due to statement timeout/)
  end
end
