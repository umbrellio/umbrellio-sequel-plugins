# frozen_string_literal: true

module Sequel::Plugins::WithLock
  module InstanceMethods
    # Execute block with lock
    #
    # @yield
    def with_lock(mode = "FOR NO KEY UPDATE", savepoint: true)
      return yield if @__locked
      @__locked = true

      begin
        db.transaction(savepoint: savepoint) do
          lock!(mode)
          yield
        end
      ensure
        @__locked = false
      end
    end
  end
end
