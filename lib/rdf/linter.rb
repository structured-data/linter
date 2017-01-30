require 'sinatra/linkeddata'
require 'json/ld/preloaded' # Preload certain contexts
require 'rdf/vocab/schema'
require 'rdf/vocab/schema_context'
require 'rdf/reasoner'
require 'rdf/linter/extensions'
require 'rdf/vocab'
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
    autoload :Vocab,        'rdf/linter/vocab'
    autoload :Schema,       'rdf/linter/schema'

    APP_DIR = File.expand_path("../../..", __FILE__)
    CACHE_DIR = File.join(APP_DIR, 'cache')
    PUB_DIR = File.join(APP_DIR, 'public')
    LINTER_DIR = File.join(APP_DIR, 'lib/rdf/linter')
    SNIPPET_DIR = File.join(LINTER_DIR, 'snippets')

    def self.debug?; @debug; end
    def self.debug=(value); @debug = value; end
  end
end
