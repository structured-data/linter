source 'http://rubygems.org'

gemspec
ruby "2.5.0"

# Include non-released gems first
gem "sinatra-linkeddata", git: "https://github.com/ruby-rdf/sinatra-linkeddata", branch: "develop"
gem "rack-linkeddata",    git: "https://github.com/ruby-rdf/rack-linkeddata", branch: "develop"
gem "linkeddata",         git: "https://github.com/ruby-rdf/linkeddata", branch: "develop"
gem "rdf",                git: "https://github.com/ruby-rdf/rdf", branch: "develop"
gem "rdf-spec",           git: "https://github.com/ruby-rdf/rdf-spec", branch: "develop"

gem 'rdf-aggregate-repo', git: "https://github.com/ruby-rdf/rdf-aggregate-repo", branch: "develop"
gem 'rdf-isomorphic',     git: "https://github.com/ruby-rdf/rdf-isomorphic", branch: "develop"
gem 'rdf-do',             git: "https://github.com/ruby-rdf/rdf-do", branch: "develop"
gem 'rdf-json',           git: "https://github.com/ruby-rdf/rdf-json", branch: "develop"
gem 'rdf-microdata',      git: "https://github.com/ruby-rdf/rdf-microdata", branch: "develop"
gem 'rdf-n3',             git: "https://github.com/ruby-rdf/rdf-n3", branch: "develop"
gem 'rdf-normalize',      git: "https://github.com/ruby-rdf/rdf-normalize", branch: "develop"
gem 'rdf-rdfa',           git: "https://github.com/ruby-rdf/rdf-rdfa", branch: "develop"
gem 'rdf-rdfxml',         git: "https://github.com/ruby-rdf/rdf-rdfxml", branch: "develop"
gem 'rdf-reasoner',       git: "https://github.com/ruby-rdf/rdf-reasoner", branch: "develop"
gem 'rdf-tabular',        git: "https://github.com/ruby-rdf/rdf-tabular", branch: "develop"
gem 'rdf-trig',           git: "https://github.com/ruby-rdf/rdf-trig", branch: "develop"
gem 'rdf-trix',           git: "https://github.com/ruby-rdf/rdf-trix", branch: "develop"
gem 'rdf-turtle',         git: "https://github.com/ruby-rdf/rdf-turtle", branch: "develop"
gem 'rdf-vocab',          git: "https://github.com/ruby-rdf/rdf-vocab", branch: "develop"
gem 'rdf-xsd',            git: "https://github.com/ruby-rdf/rdf-xsd", branch: "develop"
gem 'json-ld',            git: "https://github.com/ruby-rdf/json-ld", branch: "develop"
gem 'json-ld-preloaded',  git: "https://github.com/ruby-rdf/json-ld-preloaded", branch: "develop"
gem 'ld-patch',           git: "https://github.com/ruby-rdf/ld-patch", branch: "develop"
gem 'shex',               git: "https://github.com/ruby-rdf/shex", branch: "develop"
gem 'sparql',             git: "https://github.com/ruby-rdf/sparql", branch: "develop"
gem 'sparql-client',      git: "https://github.com/ruby-rdf/sparql-client", branch: "develop"
gem 'sxp',                git: "https://github.com/dryruby/sxp.rb", branch: "develop"
gem "syntax"
gem 'better_errors'
gem 'binding_of_caller'

group :development, :test do
  gem 'rake'
  gem 'simplecov', require: false
end

# Becuase rest-client-commonents doesn't seem like it's going to be updated:
gem 'rest-client-components', git: "https://github.com/amatriain/rest-client-components", branch: "rest-client-2-compatibility"

# Until Tilt is updated to remove (issue #316)
#gem 'tilt',               git: "https://github.com/rtomayko/tilt"

gem 'jsonlint',           git: "https://github.com/dougbarth/jsonlint"

group :debug do
  gem 'shotgun'
  gem "byebug"
end
