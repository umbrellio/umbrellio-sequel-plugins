# frozen_string_literal: true

RSpec.describe 'methods_in_migrations' do
  specify do
    stub_const('INTERCEPTOR', [])

    migration = Sequel.migration do
      def simple_method(direction)
        INTERCEPTOR << direction
      end

      up   { simple_method(:up) }
      down { simple_method(:down) }
    end

    migration.apply(DB, :up)
    expect(INTERCEPTOR).to contain_exactly(:up)

    migration.apply(DB, :down)
    expect(INTERCEPTOR).to contain_exactly(:up, :down)
  end
end
