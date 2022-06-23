# frozen_string_literal: true

Sequel.migration do
  transaction_options(rollback: :always)

  up { create_table :third_table }
  down { drop_table :third_table }
end
