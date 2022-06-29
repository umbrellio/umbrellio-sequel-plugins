# frozen_string_literal: true

require "rails/command"
require "rails/commands/dbconsole/dbconsole_command"

class Rails::Command::DbconsoleCommand < Rails::Command::Base
  def perform
    require "rake"
    Rake.with_application(&:load_rakefile) # Needed to initialize Rails.application
    Rails::DBConsole.start(options)
  end
end

class Rails::DBConsole
  DBConfig = Struct.new(:configuration_hash, :adapter, :database)

  private

  def db_config
    @db_config ||= DBConfig.new(configuration_hash, adapter, database)
  end

  def configuration_hash
    return @configuration_hash if defined?(@configuration_hash)

    rails_db_config = Rails.application.config.database_configuration

    sequel_configuration = SequelRails::Configuration.new
    SequelRails.configuration = sequel_configuration.merge!(raw: rails_db_config)

    storage = SequelRails::Storage.adapter_for(Rails.env)
    @configuration_hash = storage.config.with_indifferent_access
  end

  def adapter
    configuration_hash.fetch(:adapter)
  end

  def database
    @options[:database] || configuration_hash.fetch(:database)
  end
end
