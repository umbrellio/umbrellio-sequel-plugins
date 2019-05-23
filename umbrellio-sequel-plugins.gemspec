# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  gem_version = "0.3.0"
  release_version = ENV["TRAVIS"] ? "#{gem_version}.#{ENV["TRAVIS_BUILD_NUMBER"]}" : gem_version

  spec.name = "umbrellio-sequel-plugins"
  spec.version = release_version
  spec.required_ruby_version = ">= 2.4"

  spec.authors = ["nulldef"]
  spec.email = ["nulldefiner@gmail.com", "oss@umbrellio.biz"]
  spec.homepage = "https://github.com/umbrellio/umbrellio-sequel-plugins"
  spec.licenses = ["MIT"]
  spec.summary = "Sequel plugins"
  spec.description = "Sequel plugins"

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sequel"
  spec.add_runtime_dependency "symbiont-ruby", ">= 0.6"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "rubocop-config-umbrellio"
  spec.add_development_dependency "simplecov"
end
