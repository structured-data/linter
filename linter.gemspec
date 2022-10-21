#!/usr/bin/env ruby -rubygems
# -*- encoding: utf-8 -*-

Gem::Specification.new do |gem|
  gem.version            = File.read('VERSION').chomp
  gem.date               = File.mtime('VERSION').strftime('%Y-%m-%d')

  gem.name               = 'linter'
  gem.homepage           = 'http://structured-data.org/'
  gem.license            = 'Unlicense'
  gem.summary            = 'Extract Microdata, RDFa and JSON-LD to provide Rich Snippet preview and analysis of structured data.'
  gem.description        = gem.summary

  gem.authors            = ['Gregg Kellogg', 'Stéphane Corlosquet']
  gem.email              = 'structured-data-dev@googlegroups.com'

  gem.platform           = Gem::Platform::RUBY
  gem.files              = %w(README.md VERSION) + Dir.glob('lib/**/*.rb')
  gem.require_paths      = %w(lib)

  gem.required_ruby_version       = '>= 3.0'
  gem.requirements                = []
  gem.add_runtime_dependency      'activesupport',      '~> 5.0'
  gem.add_runtime_dependency      'equivalent-xml'
  gem.add_runtime_dependency      'erubis',             '~> 2.7'
  gem.add_runtime_dependency      'haml',               '~> 5.2'
  gem.add_runtime_dependency      'json-ld',            '~> 3.1'
  gem.add_runtime_dependency      'json-ld-preloaded',  '~> 3.1'
  gem.add_runtime_dependency      'nokogiri',           '~> 1.13', '>= 1.13.8'
  gem.add_runtime_dependency      'puma',               '~> 5.5'
  gem.add_runtime_dependency      'rack-cache',         '~> 1.13'
  gem.add_runtime_dependency      'rdf',                '~> 3.1', '>= 3.1.15'
  gem.add_runtime_dependency      'rdf-microdata',      '~> 3.1'
  gem.add_runtime_dependency      'rdf-rdfa',           '~> 3.1'
  gem.add_runtime_dependency      'rdf-rdfxml',         '~> 3.1'
  gem.add_runtime_dependency      'rdf-reasoner',       '~> 0.7'
  gem.add_runtime_dependency      'rdf-turtle',         '~> 3.1'
  gem.add_runtime_dependency      'rdf-vocab',          '~> 3.1'
  gem.add_runtime_dependency      'rdf-xsd',            '~> 3.1'
  gem.add_runtime_dependency      'sass',               '~> 3.7'
  gem.add_runtime_dependency      'sinatra',            '~> 2.2'
  gem.add_runtime_dependency      'sinatra-rdf',        '~> 3.1'
  gem.add_runtime_dependency      'sinatra-asset-pipeline', '~> 2.2'
  gem.add_runtime_dependency      'sprockets-helpers',  '~> 1.4'
  gem.add_runtime_dependency      'uglifier',           '~> 4.2'

  gem.add_development_dependency  'foreman'
  gem.add_development_dependency  'yard' ,              '~> 0.9', ">= 0.9.26"
  gem.add_development_dependency  'shotgun',            '~> 0.9'
  gem.add_development_dependency  'rspec',              '~> 3.10'
  gem.add_development_dependency  'rspec-its',          '~> 1.3'
  gem.add_development_dependency  'rack-test',          '~> 1.1'
  gem.post_install_message        = nil
end
