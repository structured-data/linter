source 'http://rubygems.org'

# Include non-released gems first
gem 'addressable',      '2.2.4'
gem 'rdf',              :git => "git://github.com/gkellogg/rdf.git", :branch => "0.4.x"
gem 'linkeddata',       :git => "git://github.com/gkellogg/linkeddata.git", :branch => "0.4.x"
gem 'rack-linkeddata',  :git => "git://github.com/gkellogg/rack-linkeddata.git", :branch => "0.4.x", :require => "rack/linkeddata"
gem 'rdf-json',         :git => "git://github.com/gkellogg/rdf-json.git", :branch => "0.4.x", :require => 'rdf/json'
gem 'rdf-trix',         :git => "git://github.com/gkellogg/rdf-trix.git", :branch => "0.4.x", :require => 'rdf/trix'
gem 'rdf-n3',           :git => "git://github.com/gkellogg/rdf-n3.git", :require => 'rdf/n3'
gem 'rdf-microdata',    :git => "git://github.com/gkellogg/rdf-microdata.git", :require => 'rdf/microdata'
gem 'rdf-rdfa',         :git => "git://github.com/gkellogg/rdf-rdfa.git", :require => 'rdf/rdfa'
gem 'rdf-rdfxml',       :git => "git://github.com/gkellogg/rdf-rdfxml.git", :require => 'rdf/rdfxml'
gem 'json-ld',          :git => "git://github.com/gkellogg/json-ld.git", :require => 'json/ld'

gem 'sinatra',            '>= 1.2.1'
gem 'sinatra-linkeddata', :git => "git://github.com/gkellogg/sinatra-linkeddata.git", :branch => "0.4.x", :require => "sinatra/linkeddata"
gem 'erubis',             '>= 2.6.6'
gem 'haml',               '>= 3.0.0'
gem 'facets',             '>= 2.9.1'
gem 'nokogiri'

# Bundle gems for the local environment. Make sure to
# put test-only gems in this group so their generators
# and rake tasks are available in development mode:
group :development, :test do
  gem 'shotgun'
  gem 'rspec'
  gem 'wirble'
  gem 'fastercsv', :platforms => :ruby_18
end
