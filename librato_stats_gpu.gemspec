# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'librato_stats_gpu/version'

Gem::Specification.new do |spec|
  spec.name          = 'librato_stats_gpu'
  spec.version       = LibratoStats::GPU::VERSION
  spec.authors       = ['Jesper Röjestål']
  spec.email         = ['jesper@solidtango.com']
  spec.license       = 'GPL-2.0'

  spec.summary       = 'Collect GPU stats from nvidia-smi and send to librato'
  spec.description   = 'See the github page or the README.md for more information'
  spec.homepage      = 'http://github.com/jesperrojestal/librato_stats_gpu'

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.11'
end
