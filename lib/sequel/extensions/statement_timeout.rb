# frozen_string_literal: true

module Sequel
  module StatementTimeout
    private

    def begin_new_transaction(conn, opts)
      super
      check_statement_timeout(conn, opts[:statement_timeout])
    end

    def check_statement_timeout(conn, value)
      return if value.nil?
      log_connection_execute(conn, "SET LOCAL statement_timeout = \"#{value}\"")
    end
  end

  Database.register_extension(:statement_timeout, StatementTimeout)
end
