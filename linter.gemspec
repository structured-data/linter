#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'linter'
  gem.homepage           = 'http://structured-data.org/'
  gem.license            = 'Public Domain' if gem.respond_to?(:license=)
  gem.summary            = 'Extract Microdata, RDFa and JSON-LD to provide Rich Snippet preview and analysis of structured data.'
  gem.description        = gem.summary

  gem.authors            = ['Gregg Kellogg', 'Stéphane Corlosquet']
  gem.email              = 'structured-data-dev@googlegroups.com'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(README.md VERSION) + Dir.glob('lib/**/*.rb')
  gem.require_paths      = %w(lib)
  gem.has_rdoc           = false

  gem.required_ruby_version       = '>= 2.1'
  gem.requirements                = []
  gem.add_runtime_dependency      'linkeddata',         '~> 1.1'
  gem.add_runtime_dependency      'sinatra-linkeddata', '~> 1.1'
  gem.add_runtime_dependency      'rdf-reasoner',       '~> 0.0'
  gem.add_runtime_dependency      'equivalent-xml'
  gem.add_runtime_dependency      'sinatra',            '~> 1.4'
  gem.add_runtime_dependency      'erubis',             '~> 2.7'
  gem.add_runtime_dependency      'haml',               '~> 4.0'
  gem.add_runtime_dependency      'facets',             '~> 2.9'
  gem.add_runtime_dependency      'nokogiri',           '~> 1.6'
  gem.add_runtime_dependency      'rack',               '~> 1.5'
  gem.add_runtime_dependency      'rack-cache',         '~> 1.2'

  gem.add_development_dependency  'yard' ,              '~> 0.8'
  gem.add_development_dependency  'shotgun',            '~> 0.9'
  gem.add_development_dependency  'rspec',              '~> 2.14'
  gem.add_development_dependency  'rack-test',          '~> 0.6'
  gem.post_install_message        = nil
end
