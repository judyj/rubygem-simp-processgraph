$: << File.expand_path( '../lib/', __FILE__ )
require 'date'

Gem::Specification.new do |s|
  s.name        = 'simp-processgraph'
  s.version     = '0.0.4'
  s.date        = '2016-01-06'
  s.summary     = "Visually displays process communications"
  s.description = "A program that uses dot and graphviz to graph your process relationships"
  s.authors     = ["SIMP team"]
  s.email       = 'simp@simp-project.org'
  s.files       = ["lib/simp-processgraph.rb"]
  s.homepage    =
    'https://github.com/simp/rubygem-simp-processgraph'
  #s.metadata = {
  #               'issue_tracker' => 'https://github.com/simp/rubygem-simp-processgraph/issues'
  #             }
  s.executables = 'processgraph'
  s.license       = 'Apache-2.0'

  # gem dependencies
  #   for the published gem
  s.required_ruby_version = '>=1.8.7'

  # not using this s.add_runtime_dependency 'gviz',  '~> 0.3.5'

  # for development
  s.add_development_dependency 'rake',        '~> 10'
  s.add_development_dependency 'rspec',       '~> 3'

  # simple text description of external requirements (for humans to read)
  s.requirements << 'SIMP OS installation'

  # ensure the gem is built out of versioned files
  s.files = Dir['Rakefile', '{bin,lib,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z .`.split("\0")

end
