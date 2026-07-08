# frozen_string_literal: true

require "opentelemetry-api"
require_relative "concurrent_thread_pool_helpers"

RSpec.describe "concurrent_thread_pool extension OpenTelemetry context propagation" do
  let(:db) { make_concurrent_db }
  let(:otel_key) { OpenTelemetry::Context.create_key("sequel-test") }

  after { db.disconnect rescue nil }

  it "does not propagate context when calling thread context is ROOT" do
    captured = :not_set

    db.send(:async_run) { captured = OpenTelemetry::Context.current.value(otel_key) }.__value

    expect(captured).to be_nil
  end

  it "does not error when OpenTelemetry is defined without Context" do
    db = make_concurrent_db
    stub_const("OpenTelemetry", Object.new)

    expect { db.send(:async_run) { :ok }.__value }.not_to raise_error
  ensure
    db.disconnect rescue nil
  end

  it "propagates calling-thread context to worker thread" do
    captured = nil

    OpenTelemetry::Context.with_value(otel_key, "sentinel") do
      db.send(:async_run) { captured = OpenTelemetry::Context.current.value(otel_key) }.__value
    end

    expect(captured).to eq("sentinel")
  end

  context "with single-thread executor" do
    let(:db) { make_concurrent_db(num_async_threads: 1) }

    it "restores context in worker thread after block completes" do
      OpenTelemetry::Context.with_value(otel_key, "sentinel") do
        db.send(:async_run) { :done }.__value

        value_after = Concurrent::Promises.future_on(db.async_thread_executor) do
          OpenTelemetry::Context.current.value(otel_key)
        end.value!

        expect(value_after).to be_nil
      end
    end
  end

  it "propagates context even when block raises" do
    captured = nil

    OpenTelemetry::Context.with_value(otel_key, "sentinel") do
      result = db.send(:async_run) do
        captured = OpenTelemetry::Context.current.value(otel_key)
        raise "boom"
      end

      expect { result.__value }.to raise_error(RuntimeError, "boom")
      expect(captured).to eq("sentinel")
    end
  end
end
