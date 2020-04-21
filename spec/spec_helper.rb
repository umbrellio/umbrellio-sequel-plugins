# frozen_string_literal: true

require "simplecov"
require "coveralls"

SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
  SimpleCov::Formatter::HTMLFormatter,
  Coveralls::SimpleCov::Formatter,
])

SimpleCov.start do
  add_filter "spec/"
end

require "bundler/setup"
require "sequel"
require "pry"
require_relative "../utils/database"
require_relative "../lib/umbrellio-sequel-plugins"

Dir["#{__dir__}/../lib/sequel/**/*.rb"].sort.each { |f| require f }

RSpec.configure do |config|
  config.example_status_persistence_file_path = ".rspec_status"
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end

  config.after(:suite) { clean_database! }
end
