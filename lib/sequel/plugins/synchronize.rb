# frozen_string_literal: true

# Allows you to use PostgreSQL transaction advisory locks for application-level mutexes
module Sequel::Plugins::Synchronize
  module ClassMethods
    # Watch Sequel::Synchronize#synchronize_with
    def synchronize_with(...)
      db.extension(:synchronize).synchronize_with(...)
    end
  end

  module InstanceMethods
    # Just like Sequel::Synchronize#synchronize_with,
    # but name, which is joined from args, is combined with table_name and primary_key
    def synchronize(*args, **options)
      self.class.synchronize_with(lock_key_for(args), **options) { yield(reload) }
    end

    private

    def lock_key_for(args)
      [self.class.table_name, self[primary_key], *args].flatten.join("-")
    end
  end
end
