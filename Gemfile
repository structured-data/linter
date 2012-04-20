source 'http://rubygems.org'

# Include non-released gems first
gem 'rdf',              :git => "git://github.com/gkellogg/rdf.git"
gem 'linkeddata',       :git => "git://github.com/gkellogg/linkeddata.git"
gem 'rdf-microdata',    :git => "git://github.com/gkellogg/rdf-microdata.git", :require => 'rdf/microdata'
gem 'rdf-rdfa',         :git => "git://github.com/gkellogg/rdf-rdfa.git", :require => 'rdf/rdfa'
gem 'rdf-rdfxml',       :git => "git://github.com/gkellogg/rdf-rdfxml.git", :require => 'rdf/rdfxml'
gem 'json-ld',          :git => "git://github.com/gkellogg/json-ld.git", :require => 'json/ld'

gem 'rack-linkeddata',    :git => "git://github.com/gkellogg/rack-linkeddata.git", :require => "rack/linkeddata"
gem 'sinatra-linkeddata', :git => "git://github.com/gkellogg/sinatra-linkeddata.git", :require => "sinatra/linkeddata"

gem 'equivalent-xml'
gem 'sinatra',            '>= 1.3.2'
gem 'erubis',             '>= 2.7.0'
gem 'haml',               '>= 3.0.0'
gem 'facets',             '>= 2.9.1'
gem 'nokogiri'
gem 'json',               '>= 1.6.5'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'shotgun'
  gem 'rspec'
  gem 'wirble'
  gem 'fastercsv', :platforms => :ruby_18
end
