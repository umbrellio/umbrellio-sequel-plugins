# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = "umbrellio-sequel-plugins"
  spec.version = "0.4.0"
  spec.authors = ["nulldef"]
  spec.email = ["nulldefiner@gmail.com"]
  spec.required_ruby_version = ">= 2.4"
  spec.homepage = "https://github.com/umbrellio/umbrellio-sequel-plugins"
  spec.licenses = ["MIT"]

  spec.summary = "Sequel plugins"
  spec.description = "Sequel plugins"

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_dependency "sequel"
  spec.add_runtime_dependency "sequel-connection_guard", "~> 0.1"
  spec.add_runtime_dependency "symbiont-ruby", ">= 0.6"

  spec.add_development_dependency "bundler"
  spec.add_development_dependency "coveralls"
  spec.add_development_dependency "pg"
  spec.add_development_dependency "pry"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "rspec"
  spec.add_development_dependency "simplecov"
end
