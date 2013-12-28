require 'rubygems'
require 'fileutils'
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

desc "refresh schema-org-rdf"
task :schema_dir do
  %x{git clone git@github.com:mhausenblas/schema-org-rdf.git && rm -r ./schema-org-rdf/.git}
end

desc "Create schema example index"
task :schema_examples do
  $:.unshift(File.expand_path("../lib", __FILE__))
  require 'rdf/linter'
  schema = RDF::Linter::Schema.new
  Dir.glob("schema-org-rdf/examples/**/*.{microdata,rdfa,jsonld}").each do |path|
    schema.add_example(path)
  end
  schema.trim_classes
  File.open(File.expand_path("../lib/rdf/linter/views/_schema_examples.erb", __FILE__), "w") do |f|
    f.puts("<!-- This file is created automaticaly by rake schema_examples -->")
    f.write(schema.create_partial("Thing", 0))
  end
end

desc "Generate Vocabularies"
task :gen_vocabs => %w(dc foaf gr ogp s sioc skos v xsd).map {|v| "lib/rdf/linter/vocab_defs.#{v}.json"} do
  puts "Generate lib/rdf/linter/vocab_defs.rb"
  $:.unshift(File.expand_path("../lib", __FILE__))
  require 'rdf/linter'
  File.open("lib/rdf/linter/vocab_defs.rb", "w") do |f|
    RDF::Linter::Parser.cook_vocabularies(f)
  end
end

{
  :dc => {:uri => "http://purl.org/dc/terms/"},
  :foaf => {:uri => "http://xmlns.com/foaf/0.1/"},
  :gr => {:uri => "http://purl.org/goodrelations/v1#"},
  :ogp => {:uri => "http://ogp.me/ns#"},
  :s => {:prefix => "schema", :uri => "http://schema.org/", :location => "http://schema.org/docs/schema_org_rdfa.html"},
  :sioc => {:uri => "http://rdfs.org/sioc/ns#"},
  :skos => {:uri => "http://www.w3.org/2004/02/skos/core#"},
  :v => {:uri => "http://rdf.data-vocabulary.org/#"},
  :xsd => {:uri => "http://www.w3.org/2001/XMLSchema#", :location => "http://groups.csail.mit.edu/mac/projects/tami/amord/xsd.ttl"}
}.each do |id, v|
  file "lib/rdf/linter/vocab_defs.#{id}.json" do
    puts "Generate lib/rdf/linter/vocab_defs.#{id}.json"
    $:.unshift(File.expand_path("../lib", __FILE__))
    require 'rdf/linter'
    File.open("lib/rdf/linter/vocab_defs.#{id}.json", "w") do |f|
      RDF::Linter::Parser.vocab_def(RDF::URI(v[:uri]), v.fetch(:prefix, id.to_s), v.merge(:io => f))
    end
  end
end
