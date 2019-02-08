# frozen_string_literal: true

Sequel.migration do
  up { create_table :second_table }
  down { drop_table :second_table }
end
