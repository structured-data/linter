source 'http://rubygems.org'

# Specify your gem's dependencies in github-lod.gemspec
gemspec :name => ""

# Include non-released gems first
gem 'rdf-microdata',    :git => "git://github.com/gkellogg/rdf-microdata.git", :require => 'rdf/microdata'
gem 'rdf-rdfa',         :git => "git://github.com/gkellogg/rdf-rdfa.git", :require => 'rdf/rdfa'
gem 'sinatra-linkeddata', :git => "git://github.com/gkellogg/sinatra-linkeddata.git", :require => "sinatra/linkeddata"
gem 'rack-linkeddata',    :git => "git://github.com/gkellogg/rack-linkeddata.git", :require => "rack/linkeddata"


# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'shotgun'
  gem 'rspec'
  gem 'wirble'
  gem 'fastercsv', :platforms => :ruby_18
end
