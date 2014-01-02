$:.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$:.unshift File.dirname(__FILE__)

require "bundler/setup"
require 'rubygems'
require 'simplecov'
SimpleCov.start
require 'rspec'
require 'rdf/isomorphic'
require 'rdf/linter'
require 'sinatra'
require 'matchers'

# set test environment
set :environment, :test
set :run, false
set :raise_errors, true
set :logging, false

::RSpec.configure do |c|
  c.filter_run :focus => true
  c.run_all_when_everything_filtered = true
  c.exclusion_filter = {
    :ruby => lambda { |version| !(RUBY_VERSION.to_s =~ /^#{version.to_s}/) },
  }
end

TEST_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "test_data")
EXAMPLE_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "..", "google-rs")
SCHEMA_DIR = File.join(File.expand_path(File.dirname(__FILE__)), "..", "schema-org-rdf", "examples", "Thing")
