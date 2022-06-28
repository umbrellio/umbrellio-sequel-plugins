# frozen_string_literal: true

namespace :db do
  task :console do
    rails_db_config = Rails.application.config.database_configuration

    sequel_configuration = SequelRails::Configuration.new
    SequelRails.configuration = sequel_configuration.merge!(:raw => rails_db_config)

    case storage = SequelRails::Storage.adapter_for(Rails.env)
    when SequelRails::Storage::Postgres
      config = storage.config.with_indifferent_access

      ENV["PGDATABASE"]     = config[:database] if config[:database]
      ENV["PGUSER"]         = config[:username] if config[:username]
      ENV["PGHOST"]         = config[:host] if config[:host]
      ENV["PGPORT"]         = config[:port].to_s if config[:port]
      ENV["PGPASSWORD"]     = config[:password].to_s if config[:password] && @options[:include_password]
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

task :db do
  Rake.application["db:console"].invoke
end
