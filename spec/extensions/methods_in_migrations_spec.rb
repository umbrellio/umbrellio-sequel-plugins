# frozen_string_literal: true

def outer_method(direction)
  INTERCEPTOR << "outer_#{direction}"
end

RSpec.describe "methods_in_migrations" do
  specify do
    stub_const("INTERCEPTOR", [])

    migration = Sequel.migration do
      def inner_method(direction)
        INTERCEPTOR << "inner_#{direction}"
      end

      up do
        inner_method(:up)
        outer_method(:up)
      end

      down do
        inner_method(:down)
        outer_method(:down)
      end
    end

    migration.apply(DB, :up)
    expect(INTERCEPTOR).to contain_exactly("inner_up", "outer_up")

    migration.apply(DB, :down)
    expect(INTERCEPTOR).to contain_exactly("inner_up", "outer_up", "inner_down", "outer_down")
  end
end
