# frozen_string_literal: true

module SequelPlugins
  if defined?(::Rails)
    Engine = Class.new(::Rails::Engine)
  end
end
