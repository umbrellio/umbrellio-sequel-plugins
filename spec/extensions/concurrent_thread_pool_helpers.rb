# frozen_string_literal: true

require "concurrent"

ASYNC_DB_URL = ENV.fetch("DB_URL", "postgres:///sequel_plugins")

def make_concurrent_db(**opts)
  Sequel.connect(ASYNC_DB_URL, **opts).tap { |d| d.extension(:concurrent_thread_pool) }
end
