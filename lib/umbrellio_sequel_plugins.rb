# frozen_string_literal: true

require "qonfig"

module SequelPlugins
  # :nocov:
  if defined?(::Rails)
    Engine = Class.new(::Rails::Engine)
  end
  # :nocov:
end

module Umbrellio
  module SequelPlugins
    include Qonfig::Configurable

    class << self
      # @param config_key [String, Symbol]
      # @return [Qonfig::Settings]
      def [](config_key)
        config[config_key]
      end
    end

    configuration do
      setting :extensions do
        setting :currency_rates, {}
        setting :methods_in_migrations, {}
        setting :pg_tools, {}
        setting :slave, {}
        setting :synchronize, {}
        setting :deferrable_foreign_keys do
          setting :by_default, true
        end
      end

      setting :plugins do
        setting :duplicate, {}
        setting :get_column_value, {}
        setting :money_accessors, {}
        setting :store_accessors, {}
        setting :synchronize, {}
        setting :upsert, {}
        setting :with_lock, {}
      end
    end
  end
end
