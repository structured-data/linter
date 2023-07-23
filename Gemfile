source 'http://rubygems.org'

gemspec
ruby "3.2.2"

# Include non-released gems first
gem "sinatra-rdf",        git: "https://github.com/ruby-rdf/sinatra-rdf", branch: "develop"
gem "rack-rdf",           git: "https://github.com/ruby-rdf/rack-rdf", branch: "develop"
gem "rdf",                git: "https://github.com/ruby-rdf/rdf", branch: "develop"
gem "rdf-spec",           git: "https://github.com/ruby-rdf/rdf-spec", branch: "develop"

gem 'ebnf',               git: "https://github.com/dryruby/ebnf",  branch: "develop"
gem 'rdf-microdata',      git: "https://github.com/ruby-rdf/rdf-microdata", branch: "develop"
gem 'rdf-ordered-repo',   git: "https://github.com/ruby-rdf/rdf-ordered-repo", branch: "develop"
gem 'rdf-rdfa',           git: "https://github.com/ruby-rdf/rdf-rdfa", branch: "develop"
gem 'rdf-rdfxml',         git: "https://github.com/ruby-rdf/rdf-rdfxml", branch: "develop"
gem 'rdf-reasoner',       git: "https://github.com/ruby-rdf/rdf-reasoner", branch: "develop"
gem 'rdf-turtle',         git: "https://github.com/ruby-rdf/rdf-turtle", branch: "develop"
gem 'rdf-vocab',          git: "https://github.com/ruby-rdf/rdf-vocab", branch: "develop"
gem 'rdf-xsd',            git: "https://github.com/ruby-rdf/rdf-xsd", branch: "develop"
gem 'json-ld',            git: "https://github.com/ruby-rdf/json-ld", branch: "develop"
gem 'json-ld-preloaded',  git: "https://github.com/ruby-rdf/json-ld-preloaded", branch: "develop"
gem "syntax"
gem 'better_errors', '>= 2.9.1'
gem 'binding_of_caller'

group :development, :test do
  gem 'rake'
end

gem 'jsonlint',           git: "https://github.com/dougbarth/jsonlint"

group :debug do
  gem 'shotgun', '>= 0.9.2'
  gem "byebug"
end
