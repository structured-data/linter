require 'rubygems'
require 'fileutils'
require 'rspec/core/rake_task'
require 'yard'

YARD::Rake::YardocTask.new do |y|
  y.files = Dir.glob("lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/rdf*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/json-ld/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/sparql*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/spira*/lib/**/*.rb") +
            Dir.glob("vendor/bundler/**/sxp*/lib/**/*.rb") +
            ["-"] +
            Dir.glob("*-README")
end

desc 'Default: run specs.'
task :default => :spec

desc "Create schema example index"
task :schema_examples do
  $:.unshift(File.expand_path("../lib", __FILE__))
  require 'rdf/linter'
  schema = RDF::Linter::Schema.new
  Dir.glob("schema-org-rdf/examples/*/*.html").each do |path|
    schema.add_example(path)
  end
  schema.trim_classes
  File.open(File.expand_path("../lib/rdf/linter/views/_schema_examples.erb", __FILE__), "w") do |f|
    f.puts("<!-- This file is created automaticaly by rake schema_examples -->")
    f.write(schema.create_partial("Thing", 0))
  end
end

desc "Run specs"
RSpec::Core::RakeTask.new do |t|
  # Put spec opts in a file named .rspec in root
end
