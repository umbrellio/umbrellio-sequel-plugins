# frozen_string_literal: true

require "opentelemetry-api"
require_relative "concurrent_thread_pool_helpers"

RSpec.describe "concurrent_thread_pool extension OpenTelemetry via async_job_wrapper" do
  let(:otel_key) { OpenTelemetry::Context.create_key("sequel-test") }
  let(:otel_wrapper) do
    lambda do |&block|
      ctx = OpenTelemetry::Context.current

      if ctx.equal?(OpenTelemetry::Context::ROOT)
        block
      else
        -> { OpenTelemetry::Context.with_current(ctx, &block) }
      end
    end
  end
  let(:db) { make_concurrent_db(**db_opts) }
  let(:db_opts) { { async_job_wrapper: otel_wrapper } }

  after { db.disconnect rescue nil }

  it "does not propagate context when calling thread context is ROOT" do
    captured = :not_set

    db.send(:async_run) { captured = OpenTelemetry::Context.current.value(otel_key) }.__value

    expect(captured).to be_nil
  end

  it "propagates calling-thread context to worker thread" do
    captured = nil

    OpenTelemetry::Context.with_value(otel_key, "sentinel") do
      db.send(:async_run) { captured = OpenTelemetry::Context.current.value(otel_key) }.__value
    end

    expect(captured).to eq("sentinel")
  end

  context "with single-thread executor" do
    let(:db_opts) { { num_async_threads: 1, async_job_wrapper: otel_wrapper } }

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

  context "without async_job_wrapper" do
    let(:db_opts) { {} }

    it "does not propagate OpenTelemetry context" do
      captured = :not_set

      OpenTelemetry::Context.with_value(otel_key, "sentinel") do
        db.send(:async_run) { captured = OpenTelemetry::Context.current.value(otel_key) }.__value
      end

      expect(captured).to be_nil
    end
  end
end
