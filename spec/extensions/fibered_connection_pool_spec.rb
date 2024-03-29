# frozen_string_literal: true

RSpec.describe Sequel::FiberedConnectionPool do
  describe "#initialize" do
    it "creates pool with options" do
      pool = described_class.new(DB, DB.opts)
      expect(pool.size).to eq(0)
    end
  end

  describe "#hold" do
    let(:pool) { described_class.new(DB, DB.opts) }

    it "creates connection" do
      pool.hold { 1 + 1 }
      expect(pool.size).to eq(1)
    end

    it "return connection if block not given" do
      expect(pool.hold).to be_a(Sequel::Postgres::Adapter)
    end

    it "drops connection on Sequel::DatabaseDisconnectError" do
      pool.hold { 1 + 1 }
      expect { pool.hold { raise Sequel::DatabaseDisconnectError } }.to \
        raise_error(Sequel::DatabaseDisconnectError)
      expect(pool.size).to eq(0)
    end

    it "drops connection if connection is closed" do
      pool.hold { 1 + 1 }

      expect do
        pool.hold do |connection|
          connection.close
          raise Sequel::DatabaseDisconnectError
        end
      end.to raise_error(Sequel::DatabaseDisconnectError)

      expect(pool.size).to eq(0)
    end

    it "does not drop connection on PG::Error" do
      pool.hold { 1 + 1 }
      expect { pool.hold { raise PG::Error } }.to raise_error(PG::Error)
      expect(pool.size).to eq(1)
    end
  end

  describe "#disconnect" do
    let(:pool) { described_class.new(DB, DB.opts) }

    it "close each connection" do
      pool.hold { 1 + 1 }
      expect(pool.size).to eq(1)

      pool.disconnect
      expect(pool.size).to eq(0)
    end
  end

  describe "#wait_for_connection" do
    let(:pool) do
      opts = DB.opts.dup
      opts[:max_connections] = 0

      described_class.new(DB, opts)
    end

    it "waits for connection" do
      Async do |task|
        task.async { pool.hold { expect(1 + 1).to eq(2) } }
        task.async do
          pool.instance_variable_set(:@max_connections, 1)
          pool.instance_variable_get(:@notification).signal
        end
      end
    end
  end

  describe "#find_or_create_connection" do
    let(:pool) do
      opts = Sequel::DATABASES.first.opts.dup
      opts[:max_connections] = 0

      described_class.new(Sequel::DATABASES.first, opts)
    end

    it "does not create more connections" do
      expect(pool.send(:find_or_create_connection)).to eq(nil)
    end
  end
end

RSpec.describe Sequel::ConnectionPool do
  before { allow(Sequel).to receive(:current).and_return(Fiber.current) }

  it "return Sequel::FiberedConnectionPool if Sequel.current is a Fiber" do
    expect(described_class.connection_pool_class("test")).to eq(Sequel::FiberedConnectionPool)
  end
end
