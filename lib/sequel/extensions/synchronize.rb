# frozen_string_literal: true

require "timeout"

module Sequel
  # Allows you to use PostgreSQL transaction advisory locks for application-level mutexes
  module Synchronize
    AdvisoryLockTimeoutError = Class.new(StandardError)
    LOCK_RETRY_INTERVAL = 0.5

    # Use transaction advisory lock for block of code
    #
    # @param *args [Array[Strings]] used for build lock name (just join with "-")
    # @param timeout: [Integer] hot much time (in seconds) to wait lock
    # @param savepoint: [Boolean] transaction with savepoint or not.
    # @param skip_if_locked: [Boolean]
    #
    # @example
    #   DB.synchronize_with([:ruby, :forever]) { p "Hey, I'm in transaction!"; sleep 5 }
    # @db_output
    # => BEGIN
    # => SELECT pg_try_advisory_xact_lock(3764656399) -- 'ruby-forever'
    # => COMMIT
    def synchronize_with(*args, timeout: 10, savepoint: false, skip_if_locked: false)
      key = lock_key_for(args)

      transaction(savepoint: savepoint) do
        hash = key_hash(key)
        if get_lock(key, hash, timeout: timeout, skip_if_locked: skip_if_locked)
          log_info("locked with #{key} (#{hash})")
          yield
        end
      end
    end

    private

    def get_lock(key, hash, timeout:, skip_if_locked:)
      return acquire_lock(key, hash) if skip_if_locked

      Timeout.timeout(timeout, AdvisoryLockTimeoutError, timeout_error_message(key, timeout)) do
        loop do
          return true if acquire_lock(key, hash)
          sleep LOCK_RETRY_INTERVAL
        end
      end
    end

    def lock_key_for(args)
      args.to_a.flatten.join("-")
    end

    def key_hash(key)
      Digest::MD5.hexdigest(key)[0..7].hex
    end

    def timeout_error_message(key, timeout)
      "Timeout exceeded for #{key} (#{timeout} seconds)"
    end

    def acquire_lock(key, hash)
      self["SELECT pg_try_advisory_xact_lock(?) -- ?", hash, key].get
    end
  end

  Database.register_extension(:synchronize, Synchronize)
end
