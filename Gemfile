source 'https://rubygems.org'

ruby "2.1.2"

# Specify your gem's dependencies in github-lod.gemspec
gemspec

gem 'unicorn'
gem 'rdf-reasoner', git: "git://github.com/gkellogg/rdf-reasoner.git", :branch => "develop"

group :development do
  gem 'rdf', path: "../rdf"
end

group :development, :test do
  gem 'rake'
  gem 'simplecov', require: false
end

group :debug do
  gem 'wirble'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem "syntax"
  gem 'byebug'
end
