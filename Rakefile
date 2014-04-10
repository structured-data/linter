require 'rubygems'
require 'fileutils'
begin
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
rescue LoadError
end

desc "Create schema example index"
task :schema_examples do
  #%x{rm -rf ./schema.org && mkdir ./schema.org}
  #%x{curl https://raw.githubusercontent.com/rvguha/schemaorg/master/data/examples.txt -o ./schema.org/examples.txt}
  $:.unshift(File.expand_path("../lib", __FILE__))
  require 'rdf/linter'
  schema = RDF::Linter::Schema.new
  schema.load_examples(File.expand_path("../schema.org/examples.txt", __FILE__))
end

namespace :vocab do
  VOCABS = {
    dc: {uri: "http://purl.org/dc/terms/"},
    foaf: {uri: "http://xmlns.com/foaf/0.1/"},
    gr: {uri: "http://purl.org/goodrelations/v1#", location: "http://www.heppnetz.de/ontologies/goodrelations/v1.owl"},
    hydra: {uri: "http://www.w3.org/ns/hydra/core#"},
    ical: {uri: "http://www.w3.org/2002/12/cal/ical#"},
    ogp: {uri: "http://ogp.me/ns#"},
    s: {prefix: "schema", uri: "http://schema.org/", location: "http://schema.org/docs/schema_org_rdfa.html"},
    sioc: {uri: "http://rdfs.org/sioc/ns#"},
    skos: {uri: "http://www.w3.org/2004/02/skos/core#"},
    v: {uri: "http://rdf.data-vocabulary.org/#", location: "local_vocabs/v.rdf"},
    vcard: {uri: "http://www.w3.org/2006/vcard/ns#"},
    xsd: {uri: "http://www.w3.org/2001/XMLSchema#", location: "http://groups.csail.mit.edu/mac/projects/tami/amord/xsd.ttl"}
  }

  $:.unshift(File.expand_path("../lib", __FILE__))
  require 'rdf/linter'
  generator = RDF::Linter::Generate.new

  desc "Clean Vocabularies"
  task :clean do
    FileUtils.rm VOCABS.keys.map {|v| "lib/rdf/linter/vocab_defs.#{v}.json"}
  end

  desc "Generate Vocabularies"
  task :generate => VOCABS.keys.map {|v| "lib/rdf/linter/vocab_defs.#{v}.json"} do
    puts "Generate lib/rdf/linter/vocab_defs.rb"
    File.open("lib/rdf/linter/vocab_defs.rb", "w") do |f|
      generator.cook_vocabularies(f)
    end
  end

  VOCABS.each do |id, v|
    file "lib/rdf/linter/vocab_defs.#{id}.json" do
      puts "Generate lib/rdf/linter/vocab_defs.#{id}.json"
      File.open("lib/rdf/linter/vocab_defs.#{id}.json", "w") do |f|
        generator.vocab_def(RDF::URI(v[:uri]), v.fetch(:prefix, id.to_s), v.merge(:io => f))
      end
    end
  end
end
