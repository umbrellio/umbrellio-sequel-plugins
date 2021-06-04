# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  gem_version = "0.5.1"
  release_version = "#{gem_version}.#{ENV["GITHUB_RUN_NUMBER"]}" if ENV["GITHUB_ACTIONS"]

  spec.name = "umbrellio-sequel-plugins"
  spec.version = release_version || gem_version
  spec.required_ruby_version = ">= 2.4"

  spec.authors = ["nulldef"]
  spec.email = ["nulldefiner@gmail.com", "oss@umbrellio.biz"]
  spec.homepage = "https://github.com/umbrellio/umbrellio-sequel-plugins"
  spec.licenses = ["MIT"]
  spec.summary = "Sequel plugins"
  spec.description = "A colletion of sequel plugins by Umbrellio"

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "sequel"
  spec.add_runtime_dependency "symbiont-ruby"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "money"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop-config-umbrellio"
  spec.add_development_dependency "simplecov"
  spec.add_development_dependency "simplecov-lcov"
end
