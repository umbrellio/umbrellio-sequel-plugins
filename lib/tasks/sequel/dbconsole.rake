# frozen_string_literal: true

require_relative "../../umbrellio_sequel_plugins/rails_commands"

task :dbconsole do
  SequelPlugins::RailsCommands.run_console!
end

task db: :dbconsole
