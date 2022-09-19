# frozen_string_literal: true

module SequelPlugins
  if defined?(::Rails)
    class Engine < ::Rails::Engine
    end
  end
end
