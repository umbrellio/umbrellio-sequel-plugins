# frozen_string_literal: true

module SequelPlugins
  require "rails/command"
  require "rails/commands/dbconsole/dbconsole_command"

  class Rails::Command::DbconsoleCommand < Rails::Command::Base
    def perform
      require "rake"
      Rake.with_application(&:load_rakefile) # Needed to initialize Rails.application
      SequelPlugins::RailsCommands.run_console!
    end
  end

  module RailsCommands
    def self.run_console!
      rails_db_config = Rails.application.config.database_configuration

      sequel_configuration = SequelRails::Configuration.new
      SequelRails.configuration = sequel_configuration.merge!(raw: rails_db_config)

      case storage = SequelRails::Storage.adapter_for(Rails.env)
      when SequelRails::Storage::Postgres
        config = storage.config.with_indifferent_access

        ENV["PGDATABASE"]     = config[:database] if config[:database]
        ENV["PGUSER"]         = config[:username] if config[:username]
        ENV["PGHOST"]         = config[:host] if config[:host]
        ENV["PGPORT"]         = config[:port].to_s if config[:port]
        ENV["PGPASSWORD"]     = config[:password].to_s if config[:password]
        ENV["PGSSLMODE"]      = config[:sslmode].to_s if config[:sslmode]
        ENV["PGSSLCERT"]      = config[:sslcert].to_s if config[:sslcert]
        ENV["PGSSLKEY"]       = config[:sslkey].to_s if config[:sslkey]
        ENV["PGSSLROOTCERT"]  = config[:sslrootcert].to_s if config[:sslrootcert]

        exec "psql"
      else
        abort "Unsupported storage adapter: #{storage.class.inspect}"
      end
    end
  end
end
