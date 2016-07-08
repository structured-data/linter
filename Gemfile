source 'https://rubygems.org'

ruby "2.3.1"

gemspec

gem 'rdf',            git: "git://github.com/ruby-rdf/rdf.git", branch: "develop"
gem 'rdf-microdata',  git: "git://github.com/ruby-rdf/rdf-microdata.git", branch: "develop"
gem 'rdf-rdfa',       git: "git://github.com/ruby-rdf/rdf-rdfa.git", branch: "develop"
gem 'rdf-reasoner',   git: "git://github.com/ruby-rdf/rdf-reasoner.git", branch: "develop"
gem 'rdf-turtle',     git: "git://github.com/ruby-rdf/rdf-turtle.git", branch: "develop"
gem 'rdf-vocab',      git: "git://github.com/ruby-rdf/rdf-vocab.git", branch: "develop"
gem 'json-ld',        git: "git://github.com/ruby-rdf/json-ld.git", branch: "develop"
gem 'jsonlint',       git: "git://github.com/dougbarth/jsonlint.git"

group :development, :test do
  gem 'rake'
  gem 'simplecov', require: false
end

group :debug do
  gem 'byebug'
  gem 'wirble'
  gem 'better_errors'
  gem 'binding_of_caller'
  gem "syntax"
end
