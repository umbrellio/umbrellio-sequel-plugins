# frozen_string_literal: true

module Sequel
  module Plugins
    # Concurrent eager loading using concurrent_thread_pool extension.
    # Adapted from Sequel's built-in concurrent_eager_loading plugin but uses
    # our concurrent_thread_pool extension instead of async_thread_pool.
    #
    # Usage:
    #
    #   DB.extension(:concurrent_thread_pool)
    #   Album.plugin :concurrent_thread_pool_eager_loading
    #   Album.eager_load_concurrently.eager(:artist, :genre, :tracks).all
    #
    #   # Always concurrent by default:
    #   Album.plugin :concurrent_thread_pool_eager_loading, always: true
    module ConcurrentThreadPoolEagerLoading
      def self.configure(mod, opts = OPTS)
        if opts.key?(:always)
          mod.instance_variable_set(:@always_eager_load_concurrently, opts[:always])
        end
      end

      module ClassMethods
        Plugins.inherited_instance_variables(self, :@always_eager_load_concurrently => nil)
        Plugins.def_dataset_methods(self, [:eager_load_concurrently, :eager_load_serially])

        def always_eager_load_concurrently?
          @always_eager_load_concurrently
        end
      end

      module DatasetMethods
        def eager_load_concurrently
          cached_dataset(:_eager_load_concurrently) do
            clone(eager_load_concurrently: true)
          end
        end

        def eager_load_serially
          cached_dataset(:_eager_load_serially) do
            clone(eager_load_concurrently: false)
          end
        end

        private

        def eager_load_concurrently?
          v = @opts[:eager_load_concurrently]
          v.nil? ? model.always_eager_load_concurrently? : v
        end

        def perform_eager_loads(eager_load_data)
          return super if !eager_load_concurrently? || eager_load_data.length < 2

          mutex = Mutex.new
          eager_load_data.each_value do |elo|
            elo[:mutex] = mutex
          end

          super.each do |v|
            if v.is_a?(Sequel::Database::ConcurrentThreadPool::BaseProxy)
              v.__value
            end
          end
        end

        def perform_eager_load(loader, elo)
          elo[:mutex] ? db.send(:async_run) { super } : super
        end
      end
    end
  end
end
