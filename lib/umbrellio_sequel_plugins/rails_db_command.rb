# frozen_string_literal: true

require "rails/command"
require "rails/commands/dbconsole/dbconsole_command"

class Rails::Command::DbconsoleCommand < Rails::Command::Base
  class_option :server, type: :string, desc: "Specifies the server to use."

  def perform
    require "rake"
    Rake.with_application(&:load_rakefile) # Needed to initialize Rails.application
    start!
  end

  private

  # See ActiveRecord::ConnectionAdapters::PostgreSQLAdapter.dbconsole
  def start!
    ENV["PGUSER"] = pg_config[:username] if pg_config[:username]
    ENV["PGHOST"] = pg_config[:host] if pg_config[:host]
    ENV["PGPORT"] = pg_config[:port].to_s if pg_config[:port]

    if pg_config[:password] && options[:include_password]
      ENV["PGPASSWORD"] = pg_config[:password].to_s
    end

    ENV["PGSSLMODE"] = pg_config[:sslmode].to_s if pg_config[:sslmode]
    ENV["PGSSLCERT"] = pg_config[:sslcert].to_s if pg_config[:sslcert]
    ENV["PGSSLKEY"] = pg_config[:sslkey].to_s if pg_config[:sslkey]
    ENV["PGSSLROOTCERT"] = pg_config[:sslrootcert].to_s if pg_config[:sslrootcert]

    if pg_config[:variables]
      ENV["PGOPTIONS"] = pg_config[:variables].filter_map do |name, value|
        "-c #{name}=#{value.to_s.gsub(/[ \\]/, '\\\\\0')}" unless value.in?([":default", :default])
      end.join(" ")
    end

    find_cmd_and_exec("psql", database)
  end

  def pg_config
    @pg_config ||= begin
      rails_db_config = Rails.application.config.database_configuration

      sequel_configuration = SequelRails::Configuration.new
      SequelRails.configuration = sequel_configuration.merge!(raw: rails_db_config)

      storage = SequelRails::Storage.adapter_for(Rails.env)
      config = storage.config.with_indifferent_access

      if @options[:server]
        server_config = config.fetch(:servers).fetch(@options[:server])
        config.merge!(server_config)
      end

      config
    end
  end

  # See ActiveRecord::ConnectionAdapters::AbstractAdapter.find_cmd_and_exec
  def find_cmd_and_exec(commands, *args) # rubocop:disable Metrics/MethodLength
    commands = Array(commands)

    dirs_on_path = ENV["PATH"].to_s.split(File::PATH_SEPARATOR)
    unless (ext = RbConfig::CONFIG["EXEEXT"]).empty?
      commands = commands.map { |cmd| "#{cmd}#{ext}" }
    end

    full_path_command = nil
    found = commands.detect do |cmd|
      dirs_on_path.detect do |path|
        full_path_command = File.join(path, cmd)
        begin
          stat = File.stat(full_path_command)
        rescue SystemCallError
        else
          stat.file? && stat.executable?
        end
      end
    end

    if found
      exec(*[full_path_command, *args].compact)
    else
      abort(
        "Couldn't find database client: #{commands.join(', ')}. Check your $PATH and try again.",
      )
    end
  end

  def database
    options[:database] || pg_config.fetch(:database)
  end
end
