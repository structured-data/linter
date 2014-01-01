require 'sinatra/linkeddata'
require 'rdf/all'
require 'rdf/linter/extensions'
require 'find'
require 'net/http'
require 'uri'
require 'logger'

module RDF
  module Linter
    autoload :Application,  'rdf/linter/application'
    autoload :Generate,     'rdf/linter/generate'
    autoload :Parser,       'rdf/linter/parser'
    autoload :VERSION,      'rdf/linter/version'
    autoload :Schema,       'rdf/linter/schema'

    def self.debug?; @debug; end
    def self.debug=(value); @debug = value; end
  end
end
