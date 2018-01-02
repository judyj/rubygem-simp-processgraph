$: << File.expand_path( '../lib/', __FILE__ )
require 'simp/processgraph/version'
require 'date'

Gem::Specification.new do |s|
  s.name        = 'simp-processgraph'
  s.version     = Simp::ProcessGraph::VERSION
  s.date        = Date.today.to_s
  s.summary     = "Visually displays process communications"
  s.description = "A program that uses dot and graphviz to graph your process relationships"
  s.authors     = ["SIMP team"]
  s.email       = 'simp@simp-project.org'
  s.files       = ["lib/simp-processgraph.rb"]
  s.homepage    = 'https://github.com/simp/rubygem-simp-processgraph'
  # s.metadata does not seem to work in ruby < 2, so it fails the travis test unless we have it commented out
  # s.metadata = {
  #               'issue_tracker' => 'https://simp-project.atlassian.net'
  #             }
  s.executables = 'processgraph'
  s.license       = 'Apache-2.0'

  # gem dependencies
  #   for the published gem
  s.required_ruby_version = '>=1.8.7'

  # for development
  s.add_development_dependency 'rake',        '~> 10'
  s.add_development_dependency 'rspec',       '~> 3'

  # simple text description of external requirements (for humans to read)
  s.requirements << 'SIMP OS installation'

  # ensure the gem is built out of versioned files
  s.files = Dir['Rakefile', '{bin,lib,spec}/**/*', 'README*', 'LICENSE*'] & `git ls-files -z .`.split("\0")

end
