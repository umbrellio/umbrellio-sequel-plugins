# frozen_string_literal: true

module Sequel
  # Extension for choosing a slave server
  module Slave
    # Turn to slave
    #
    # @example
    #   DB[:users].slave.where(email: "test@test.com") # executes on a slave server
    # @return [Sequel::Dataset] dataset
    def slave
      server(:slave)
    end
  end

  Model.extend(Slave)
  Dataset.register_extension(:slave, Slave)
end
