source 'https://rubygems.org'

ruby "2.1.5"

# Specify your gem's dependencies in linter.gemspec
gemspec

gem 'unicorn'
gem 'curb',           '~> 0.8'
gem 'rdf',            git: "git://github.com/ruby-rdf/rdf.git", branch: "develop"
gem 'rdf-rdfa',       git: "git://github.com/ruby-rdf/rdf-rdfa.git", branch: "develop"
gem 'rdf-microdata',  git: "git://github.com/ruby-rdf/rdf-microdata.git", branch: "develop"
gem 'rdf-reasoner',   git: "git://github.com/ruby-rdf/rdf-reasoner.git", branch: "develop"
gem 'json-ld',        git: "git://github.com/ruby-rdf/json-ld.git", branch: "develop"
gem 'jsonlint',       git: "git://github.com/dougbarth/jsonlint.git"
gem 'rest-client',            '~> 1.8'
gem 'rest-client-components', '~> 1.4'

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
