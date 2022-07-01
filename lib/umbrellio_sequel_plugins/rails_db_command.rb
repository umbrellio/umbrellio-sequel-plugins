# frozen_string_literal: true

require "rails/command"
require "rails/commands/dbconsole/dbconsole_command"

class Rails::Command::DbconsoleCommand < Rails::Command::Base
  class_option :server, type: :string, desc: "Specifies the server to use."

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
    config = storage.config.with_indifferent_access

    if @options[:server]
      server_config = config.fetch(:servers).fetch(@options[:server])
      config.merge!(server_config)
    end

    @configuration_hash = config
  end

  def adapter
    mapping = SequelRails::DbConfig::ADAPTER_MAPPING.invert
    value = configuration_hash.fetch(:adapter)
    mapping[value] || value
  end

  def database
    @options[:database] || configuration_hash.fetch(:database)
  end
end
