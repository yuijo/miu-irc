# -*- encoding: utf-8 -*-
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'miu/nodes/irc/version'

Gem::Specification.new do |gem|
  gem.name          = "miu-irc"
  gem.version       = Miu::Nodes::IRC::VERSION
  gem.authors       = ["mashiro"]
  gem.email         = ["mail@mashiro.org"]
  gem.description   = %q{irc plugin for miu}
  gem.summary       = gem.description
  gem.homepage      = ""

  gem.files         = `git ls-files`.split($/)
  gem.executables   = gem.files.grep(%r{^bin/}).map{ |f| File.basename(f) }
  gem.test_files    = gem.files.grep(%r{^(test|spec|features)/})
  gem.require_paths = ["lib"]

  gem.add_dependency 'miu', '>= 0.2.2'
  gem.add_dependency 'ircp', '>= 1.1.7'
  gem.add_dependency 'celluloid-io', '>= 0.14.0'
  gem.add_dependency 'celluloid-zmq', '>= 0.14.0'
  gem.add_development_dependency 'rake', '>= 10.0.3'
end
