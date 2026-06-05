# frozen_string_literal: true

require "concurrent"

module Sequel
  # https://github.com/jeremyevans/sequel/blob/master/lib/sequel/extensions/async_thread_pool.rb
  module Database::ConcurrentThreadPool

    # Base proxy: delegates all method calls to the resolved async value.
    class BaseProxy < BasicObject
      def method_missing(*args, &block)
        __value.public_send(*args, &block)
      end

      # :nocov:
      ruby2_keywords(:method_missing) if respond_to?(:ruby2_keywords, true)
      # :nocov:

      def respond_to_missing?(*args)
        __value.respond_to?(*args)
      end

      [:!, :==, :!=, :instance_eval, :instance_exec].each do |method|
        define_method(method) do |*args, &block|
          __value.public_send(method, *args, &block)
        end
      end
    end

    # Default proxy: schedules block via Concurrent::Future, blocks on first access.
    class Proxy < BaseProxy
      def initialize(executor, &block)
        @future = ::Concurrent::Future.execute(executor: executor, &block)
      end

      def __value
        @future.value!
      end
    end

    # Preemptable proxy: calling thread runs the block if the pool hasn't started it yet.
    class PreemptableProxy < BaseProxy
      def initialize(executor, &block)
        @mutex = ::Mutex.new
        @block = block
        @done = false
        @result = nil
        @error = nil

        executor.post { __run }
      end

      def __value
        error, result = @mutex.synchronize do
          __execute unless @done
          [@error, @result]
        end
        ::Kernel.raise error if error
        result
      end

      private

      def __run
        @mutex.synchronize { __execute unless @done }
      end

      def __execute
        @result = @block.call
      rescue ::Exception => e
        @error = e
      ensure
        @done = true
      end
    end

    module DatabaseMethods
      def self.extended(db)
        db.instance_exec do
          case pool.pool_type
          when :single, :sharded_single
            raise Error, "cannot load async_thread_pool extension if using single or sharded_single connection pool"
          end

          executor, owned = if opts[:async_thread_executor]
            [opts[:async_thread_executor], false]
          elsif opts[:num_async_threads]
            num = typecast_value_integer(opts[:num_async_threads])
            raise Error, "must have positive number for num_async_threads" if num <= 0
            [::Concurrent::ThreadPoolExecutor.new(
              min_threads: num,
              max_threads: num,
              max_queue: 0,
              fallback_policy: :abort,
            ), true]
          else
            [::Concurrent.global_io_executor, false]
          end

          proxy_klass = typecast_value_boolean(opts[:preempt_async_thread]) ? PreemptableProxy : Proxy

          define_singleton_method(:async_job_class) { proxy_klass }
          define_singleton_method(:async_thread_executor) { executor }

          ObjectSpace.define_finalizer(db, proc { executor.shutdown }) if owned

          extend_datasets(DatasetMethods)
        end
      end

      private

      def async_run(&block)
        async_job_class.new(async_thread_executor, &block)
      end
    end

    ASYNC_METHODS = (
      [:all?, :any?, :drop, :entries, :grep_v, :include?, :inject, :member?, :minmax,
       :none?, :one?, :reduce, :sort, :take, :tally, :to_a, :to_h, :uniq, :zip] & Enumerable.instance_methods
    ) + (Dataset::ACTION_METHODS - [:map, :paged_each])

    ASYNC_BLOCK_METHODS = (
      [:collect, :collect_concat, :detect, :drop_while, :each_cons, :each_entry, :each_slice,
       :each_with_index, :each_with_object, :filter_map, :find, :find_all, :find_index,
       :flat_map, :max_by, :min_by, :minmax_by, :partition, :reject, :reverse_each,
       :sort_by, :take_while] & Enumerable.instance_methods
    ) + [:paged_each]

    ASYNC_ARGS_OR_BLOCK_METHODS = [:map]

    module DatasetMethods
      def self.define_async_method(mod, method)
        mod.send(:define_method, method) do |*args, &block|
          if @opts[:async]
            ds = sync
            db.send(:async_run) { ds.send(method, *args, &block) }
          else
            super(*args, &block)
          end
        end
      end

      def self.define_async_block_method(mod, method)
        mod.send(:define_method, method) do |*args, &block|
          if block && @opts[:async]
            ds = sync
            db.send(:async_run) { ds.send(method, *args, &block) }
          else
            super(*args, &block)
          end
        end
      end

      def self.define_async_args_or_block_method(mod, method)
        mod.send(:define_method, method) do |*args, &block|
          if (block || !args.empty?) && @opts[:async]
            ds = sync
            db.send(:async_run) { ds.send(method, *args, &block) }
          else
            super(*args, &block)
          end
        end
      end

      ASYNC_METHODS.each { |m| define_async_method(self, m) }
      ASYNC_BLOCK_METHODS.each { |m| define_async_block_method(self, m) }
      ASYNC_ARGS_OR_BLOCK_METHODS.each { |m| define_async_args_or_block_method(self, m) }

      def async
        cached_dataset(:_async) { clone(async: true) }
      end

      def sync
        cached_dataset(:_sync) { clone(async: false) }
      end
    end
  end

  Database.register_extension(:concurrent_thread_pool, Database::ConcurrentThreadPool::DatabaseMethods)
end
