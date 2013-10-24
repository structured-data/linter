#!/usr/bin/env rackup
$:.unshift(File.expand_path('../lib',  __FILE__))

require 'rubygems' || Gem.clear_paths
require 'bundler'
Bundler.setup(:default)

require 'rack/cache'
require 'sinatra'
require 'sinatra/base'
require 'rdf/linter'
require 'logger'

set :environment, (ENV['RACK_ENV'] || 'production').to_sym

case settings.environment
when :production
  puts "Mode set to production, logging to sinatra.log"
  $logger = Logger.new('sinatra.log', 10, 3600*24*7)
else
  $logger = Logger.new(STDOUT)
  $logger.formatter = lambda {|severity, datetime, progname, msg| "#{msg}\n"}
end

#use Rack::Cache,
#  :verbose     => true,
#  :metastore   => "file:" + File.expand_path("../cache/meta", __FILE__),
#  :entitystore => "file:" + File.expand_path("../cache/body", __FILE__)

disable :run, :reload

run RDF::Linter::Application
