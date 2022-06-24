# frozen_string_literal: true

module Sequel
  module SetLocal
    private

    def begin_new_transaction(conn, opts)
      super
      check_set_local(conn, opts[:set_local])
    end

    def check_set_local(conn, locals)
      return if locals.nil?

      locals.each do |key, value|
        log_connection_execute(conn, "SET LOCAL #{key} = \"#{value}\"")
      end
    end
  end

  Database.register_extension(:set_local, SetLocal)
end
