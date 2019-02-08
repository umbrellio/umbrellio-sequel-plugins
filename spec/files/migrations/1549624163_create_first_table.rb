# frozen_string_literal: true

Sequel.migration do
  up { create_table :first_table }
  down { drop_table :first_table }
end
