# frozen_string_literal: true

require "concurrent"

ASYNC_DB_URL = ENV.fetch("DB_URL", "postgres:///sequel_plugins")

def make_concurrent_db(**opts)
  Sequel.connect(ASYNC_DB_URL, **opts).tap { |d| d.extension(:concurrent_thread_pool) }
end

RSpec.describe "concurrent_thread_pool extension" do
  let(:db) { make_concurrent_db(**db_opts) }
  let(:db_opts) { {} }

  after { db.disconnect rescue nil }

  describe "executor configuration" do
    context "default (no options)" do
      it "uses global_io_executor" do
        expect(db.async_thread_executor).to eq(Concurrent.global_io_executor)
      end
    end

    context "with num_async_threads:" do
      let(:db_opts) { { num_async_threads: 3 } }

      it "creates dedicated ThreadPoolExecutor" do
        expect(db.async_thread_executor).to be_a(Concurrent::ThreadPoolExecutor)
        expect(db.async_thread_executor).not_to eq(Concurrent.global_io_executor)
      end

      it "respects the thread count" do
        expect(db.async_thread_executor.max_length).to eq(3)
      end
    end

    context "with async_thread_executor:" do
      let(:custom_executor) { Concurrent.global_fast_executor }
      let(:db_opts) { { async_thread_executor: custom_executor } }

      it "uses provided executor" do
        expect(db.async_thread_executor).to eq(custom_executor)
      end
    end
  end

  describe "loading errors" do
    it "raises on single_threaded connection pool" do
      d = Sequel.connect(ASYNC_DB_URL, single_threaded: true)
      expect { d.extension(:concurrent_thread_pool) }.to raise_error(Sequel::Error, /single/)
    ensure
      d&.disconnect
    end

    it "raises on num_async_threads: 0" do
      d = Sequel.connect(ASYNC_DB_URL, num_async_threads: 0)
      expect { d.extension(:concurrent_thread_pool) }.to raise_error(Sequel::Error, /positive/)
    ensure
      d&.disconnect
    end
  end

  describe "Dataset#async" do
    it "returns a proxy (not the resolved value)" do
      result = db.fetch("SELECT 1 AS val").async.all
      # be_a delegates through method_missing on BasicObject, so compare object identity
      expect(result.__id__).not_to eq(result.__value.__id__)
    end

    it "proxy resolves via __value" do
      result = db.fetch("SELECT 1 AS val").async.all
      expect(result.__value).to eq([{ val: 1 }])
    end

    it "proxy delegates method calls to resolved value" do
      result = db.fetch("SELECT 1 AS val").async.all
      expect(result.first).to eq({ val: 1 })
      expect(result.length).to eq(1)
    end

    it "proxy responds_to? based on resolved value" do
      result = db.fetch("SELECT 1 AS val").async.all
      expect(result.respond_to?(:first)).to be(true)
      expect(result.respond_to?(:nonexistent_method_xyz)).to be(false)
    end

    it "works with first" do
      result = db.fetch("SELECT 1 AS val").async.first
      expect(result[:val]).to eq(1)
    end

    it "works with map" do
      result = db.fetch("SELECT generate_series AS n FROM generate_series(1, 3)").async.map(:n)
      expect(result.__value).to eq([1, 2, 3])
    end

    it "works with count" do
      result = db.fetch("SELECT generate_series FROM generate_series(1, 5)").async.count
      expect(result.__value).to eq(5)
    end
  end

  describe "Dataset#sync" do
    it "returns non-proxy result" do
      result = db.fetch("SELECT 1 AS val").async.sync.all
      expect(result).to eq([{ val: 1 }])
    end

    it "disables async on cloned dataset" do
      async_ds = db.fetch("SELECT 1 AS val").async
      expect(async_ds.opts[:async]).to be(true)
      expect(async_ds.sync.opts[:async]).to be(false)
    end
  end

  describe "exception propagation" do
    it "re-raises DB errors on value access" do
      result = db.fetch("SELECT 1/0").async.all
      expect { result.__value }.to raise_error(Sequel::DatabaseError)
    end

    it "re-raises on delegated method call" do
      result = db.fetch("SELECT 1/0").async.all
      expect { result.first }.to raise_error(Sequel::DatabaseError)
    end
  end

  describe "concurrent execution" do
    it "runs multiple queries in parallel" do
      started_at = Process.clock_gettime(Process::CLOCK_MONOTONIC)

      r1 = db.fetch("SELECT pg_sleep(0.3), 1 AS n").async.first
      r2 = db.fetch("SELECT pg_sleep(0.3), 2 AS n").async.first
      r3 = db.fetch("SELECT pg_sleep(0.3), 3 AS n").async.first

      expect(r1[:n]).to eq(1)
      expect(r2[:n]).to eq(2)
      expect(r3[:n]).to eq(3)

      elapsed = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at
      expect(elapsed).to be < 0.7
    end
  end

  describe "thread safety of proxy" do
    it "__value returns same result across concurrent callers" do
      proxy = db.fetch("SELECT 1 AS val").async.all

      results = Array.new(8) { Thread.new { proxy.__value } }.map(&:value)
      expect(results).to all(eq([{ val: 1 }]))
    end
  end

  describe "with preempt_async_thread option" do
    let(:db_opts) { { preempt_async_thread: true } }

    it "resolves correctly" do
      result = db.fetch("SELECT 1 AS val").async.all
      expect(result.first).to eq({ val: 1 })
    end

    it "re-raises exceptions" do
      result = db.fetch("SELECT 1/0").async.all
      expect { result.__value }.to raise_error(Sequel::DatabaseError)
    end

    it "returns same result across concurrent callers" do
      proxy = db.fetch("SELECT 1 AS val").async.all

      results = Array.new(8) { Thread.new { proxy.__value } }.map(&:value)
      expect(results).to all(eq([{ val: 1 }]))
    end
  end

  describe "async_job_class" do
    it "is Proxy by default" do
      expect(db.async_job_class).to eq(Sequel::Database::ConcurrentThreadPool::Proxy)
    end

    context "with preempt_async_thread: true" do
      let(:db_opts) { { preempt_async_thread: true } }

      it "is PreemptableProxy" do
        expect(db.async_job_class).to eq(Sequel::Database::ConcurrentThreadPool::PreemptableProxy)
      end
    end
  end
end
