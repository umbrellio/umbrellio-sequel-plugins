# frozen_string_literal: true

require "logger"

DB = Sequel.connect(ENV["DB_URL"] || "postgres://localhost/sequel_plugins")
DB.logger = Logger.new("log/db.log")

Sequel::Model.db = DB

DB.extension :pg_array
DB.extension :pg_json
DB.extension :pg_range

DB.extension :currency_rates
DB.extension :pg_tools
DB.extension :slave
DB.extension :statement_timeout
DB.extension :synchronize

Sequel.extension :deferrable_foreign_keys
Sequel.extension :migration
Sequel.extension :pg_array_ops
Sequel.extension :pg_json_ops
Sequel.extension :pg_range_ops

Sequel::Model.plugin :attr_encrypted
Sequel::Model.plugin :duplicate
Sequel::Model.plugin :get_column_value
Sequel::Model.plugin :money_accessors
Sequel::Model.plugin :store_accessors
Sequel::Model.plugin :synchronize
Sequel::Model.plugin :upsert
Sequel::Model.plugin :with_lock

def clean_database!
  DB.tables.each do |table_name|
    DB.drop_table?(table_name, cascade: true)
  end
end
