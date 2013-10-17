source 'https://rubygems.org'

# Specify your gem's dependencies in github-lod.gemspec
gemspec :name => ""

# Include non-released gems first
gem 'rdf-microdata',    :git => "git://github.com/ruby-rdf/rdf-microdata.git", :require => 'rdf/microdata'
gem 'rdf-rdfa',         :git => "git://github.com/ruby-rdf/rdf-rdfa.git", :require => 'rdf/rdfa'
gem 'sinatra-linkeddata', :git => "git://github.com/ruby-rdf/sinatra-linkeddata.git", :require => "sinatra/linkeddata"
gem 'rack-linkeddata',    :git => "git://github.com/ruby-rdf/rack-linkeddata.git", :require => "rack/linkeddata"

group :development, :test do
  gem 'sparql'
  gem 'rake'
end

group :debug do
  gem 'wirble'
  gem 'debugger'
end
