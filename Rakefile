require 'rubygems'
require 'sinatra/asset_pipeline/task'
require 'rdf/linter'

namespace :doc do
  begin
    require 'yard'

    YARD::Rake::YardocTask.new
  rescue LoadError
  end
end

Sinatra::AssetPipeline::Task.define! RDF::Linter::Application

# https://raw.githubusercontent.com/schemaorg/schemaorg/sdo-callisto/data/releases/3.3/all-layers.nq
schema_base = ENV.fetch("schema_base", "https://raw.githubusercontent.com/schemaorg/schemaorg/main/data")
schema_version = ENV.fetch("schema_version", "13.0")

namespace :schema do
  desc "Create custom pre-compiled vocabularies"
  task vocab: %w(lib/rdf/vocab/schema.rb lib/rdf/vocab/schemas.rb)

  file "lib/rdf/vocab/schema.rb" => :do_build do
    puts "Generate lib/rdf/vocab/schema.rb"
    cmd = "bundle exec rdf"
    cmd += " serialize --uri http://schema.org/ --output-format vocabulary"
    cmd += " --module-name RDF::Vocab"
    cmd += " --class-name SCHEMA"
    cmd += " --strict"
    cmd += " --noDoc"
    cmd += " -o lib/rdf/vocab/schema.rb_t"
    cmd += " #{schema_base}/releases/#{schema_version}/schemaorg-current-http.nq"
    puts "  #{cmd}"
    begin
      %x{#{cmd} && mv lib/rdf/vocab/schema.rb_t lib/rdf/vocab/schema.rb}
    rescue
      puts "Failed to load schema: #{$!.message}"
    ensure
      %x{rm -f lib/rdf/vocab/schema.rb_t}
    end
  end


  file "lib/rdf/vocab/schemas.rb" => :do_build do
    puts "Generate lib/rdf/vocab/schemas.rb"
    cmd = "bundle exec rdf"
    cmd += " serialize --uri https://schema.org/ --output-format vocabulary"
    cmd += " --module-name RDF::Vocab"
    cmd += " --class-name SCHEMAS"
    cmd += " --strict"
    cmd += " --noDoc"
    cmd += " -o lib/rdf/vocab/schemas.rb_t"
    cmd += " #{schema_base}/releases/#{schema_version}/schemaorg-current-https.nq"
    puts "  #{cmd}"
    begin
      %x{#{cmd} && mv lib/rdf/vocab/schemas.rb_t lib/rdf/vocab/schemas.rb}
    rescue
      puts "Failed to load schema: #{$!.message}"
    ensure
      %x{rm -f lib/rdf/vocab/schemas.rb_t}
    end
  end

  task :do_build

  desc "Create pre-compiled context"
  task context: "lib/rdf/vocab/schema_context.rb"
  file "lib/rdf/vocab/schema_context.rb" => :do_build do
    puts "Generate lib/rdf/vocab/schema_context.rb"
    require 'json/ld'
    File.open("lib/rdf/vocab/schema_context.rb", "w") do |f|
      c = JSON::LD::Context.parse("#{schema_base}/releases/#{schema_version}/schemaorgcontext.jsonld")
      f.write c.to_rb("https://schema.org/", "http://schema.org/", "https://schema.org", "http://schema.org")
    end
  end

  desc "Create schema example index"
  task :examples do
    %x{rm -rf ./schema.org && mkdir -p ./schema.org/ext/bib ./schema.org/ext/health-lifesci}
    %x{curl #{schema_base}/releases/#{schema_version}/schemaorg-all-examples.txt -o ./schema.org/schemaorg-all-examples.txt}
    $:.unshift(File.expand_path("../lib", __FILE__))
    require 'rdf/linter'
    schema = RDF::Linter::Schema.new
    File.open(File.expand_path("../schema.org/schemaorg-all-examples.txt", __FILE__)) do |f|
      schema.load_examples(f)
    end
  end

  desc "Generate workings for schema examples"
  task :warnings do
    %x{script/parse schema.org/*.html --lint --quiet -o etc/schema-warnings.txt}
  end
end
