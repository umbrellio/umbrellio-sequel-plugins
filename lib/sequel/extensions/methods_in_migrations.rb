# frozen_string_literal: true

require 'symbiont'

Sequel::SimpleMigration.prepend(Module.new do

  def apply(db, direction)
    # :nocov:
    unless [:up, :down].include?(direction) # NOTE: original code
      raise(ArgumentError, "Invalid migration direction specified (#{direction.inspect})")
    end
    # :nocov:

    if prok = public_send(direction)
      Symbiont::Executor.evaluate(db, &prok) # NOTE: our extension
    end
  end
end)
