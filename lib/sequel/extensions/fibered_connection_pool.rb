# frozen_string_literal: true

require "async"
require "async/notification"

class Sequel::FiberedConnectionPool < Sequel::ConnectionPool
  def initialize(db, opts = Sequel::OPTS)
    super(db, opts)

    @max_connections = opts[:max_connections]
    @available_connections = []
    @notification = Async::Notification.new
    @size = 0
  end

  def hold(*)
    connection = wait_for_connection
    return connection unless block_given?

    begin
      yield connection
    rescue Sequel::DatabaseDisconnectError, *@error_classes => error
      if disconnect_error?(error)
        disconnect_connection(connection)
        connection = nil
        @size -= 1
      end
      raise
    ensure
      if connection
        @available_connections.push(connection)
        @notification.signal if Async::Task.current?
      end
    end
  end

  def disconnect(*)
    @available_connections.each(&:close)
    @available_connections.clear

    @size = 0
  end

  def size
    @size
  end

  private

  def wait_for_connection
    until (connection = find_or_create_connection)
      @notification.wait
    end

    connection
  end

  def find_or_create_connection
    if (connection = @available_connections.shift)
      return connection
    end

    if @max_connections.nil? || @size < @max_connections
      connection = make_new(:default)
      @size += 1

      return connection
    end

    nil
  end
end

module Sequel::ConnectionPoolPatch
  def connection_pool_class(*)
    Sequel.current.is_a?(Fiber) ? Sequel::FiberedConnectionPool : super
  end
end

class Sequel::ConnectionPool
  class << self
    prepend Sequel::ConnectionPoolPatch
  end
end
