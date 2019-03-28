# frozen_string_literal: true

require 'symbiont'

Sequel::SimpleMigration.prepend(Module.new do
  def apply(db, direction)
    unless [:up, :down].include?(direction)
      raise(ArgumentError, "Invalid migration direction specified (#{direction.inspect})")
    end

    if prok = public_send(direction)
      Symbiont::Executor.evaluate(db, &prok)
    end
  end
end)
