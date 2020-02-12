#!/usr/bin/env rackup
require 'rubygems' || Gem.clear_paths
require 'bundler'
Bundler.setup(:default)

require 'rack/cache'
require 'sinatra'
require 'sinatra/base'
require_relative 'lib/rdf/linter'

set :environment, (ENV['RACK_ENV'] || 'production').to_sym

if ENV['RACK_ENV'] == 'production'
  use Rack::Cache,
    :verbose     => true,
    :metastore   => "file:" + File.expand_path("../cache/meta", __FILE__),
    :entitystore => "file:" + File.expand_path("../cache/body", __FILE__)
end

disable :run, :reload

run RDF::Linter::Application
