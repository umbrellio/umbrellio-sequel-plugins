# frozen_string_literal: true

module Sequel::Plugins::WithLock
  module InstanceMethods
    # Execute block with lock
    #
    # @yield
    def with_lock
      return yield if @__locked
      @__locked = true

      begin
        db.transaction(savepoint: true) do
          lock!
          yield
        end
      ensure
        @__locked = false
      end
    end
  end
end
