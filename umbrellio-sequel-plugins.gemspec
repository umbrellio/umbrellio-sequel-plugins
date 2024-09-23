# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

Gem::Specification.new do |spec|
  spec.name = "umbrellio-sequel-plugins"
  spec.version = "0.17.0"
  spec.required_ruby_version = ">= 3.0"

  spec.authors = ["Team Umbrellio"]
  spec.email = ["oss@umbrellio.biz"]
  spec.homepage = "https://github.com/umbrellio/umbrellio-sequel-plugins"
  spec.licenses = ["MIT"]
  spec.summary = "Sequel plugins"
  spec.description = "A colletion of sequel plugins by Umbrellio"

  spec.files = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "sequel"
end
