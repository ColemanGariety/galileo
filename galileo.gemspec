# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'galileo/version'

Gem::Specification.new do |spec|
  spec.name          = "galileo"
  spec.version       = Galileo::VERSION
  spec.authors       = ["Jackson Gariety"]
  spec.email         = ["personal@jacksongariety.com"]
  spec.summary       = "Search your starred GitHub repos from the command line."
  spec.description   = "Search starred GitHub repos."
  spec.homepage      = "http://jacksongariety.github.io/galileo"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)/})
  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "octokit"
  spec.add_runtime_dependency "colorize"

  spec.add_development_dependency "bundler", "~> 1.5"
  spec.add_development_dependency "rake"
end
