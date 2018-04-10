gem_sources = ENV.fetch('GEM_SERVERS', 'https://rubygems.org').split(/[, ]+/)

gem_sources.each { |gem_source| source gem_source }

# read dependencies in from the gemspec
gemspec

# mandatory gems
gem 'bundler'
gem 'rake'

group :system_tests do
  gem 'pry'
  gem 'rspec'

  # Ruby code coverage
  gem 'simplecov'
end
