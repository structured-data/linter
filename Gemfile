source 'https://rubygems.org'

ruby "2.4.1"

gemspec

gem 'sinatra-asset-pipeline', github: 'gkellogg/sinatra-asset-pipeline', branch: 'sinatra-2'
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
