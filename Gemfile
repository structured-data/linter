source 'https://rubygems.org'

ruby "2.3.1"

gemspec

gem 'rdf',                github: "ruby-rdf/rdf", branch: "develop"
gem 'rdf-microdata',      github: "ruby-rdf/rdf-microdata", branch: "develop"
gem 'rdf-rdfa',           github: "ruby-rdf/rdf-rdfa", branch: "develop"
gem 'rdf-reasoner',       github: "ruby-rdf/rdf-reasoner", branch: "develop"
gem 'rdf-turtle',         github: "ruby-rdf/rdf-turtle", branch: "develop"
gem 'rdf-vocab',          github: "ruby-rdf/rdf-vocab", branch: "develop"
gem 'json-ld',            github: "ruby-rdf/json-ld", branch: "develop"
gem 'jsonlint',           github: "dougbarth/jsonlint"

group :development, :test do
  gem 'rake'
  gem 'simplecov', require: false
end

group :debug do
  gem 'byebug'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem "syntax"
end
