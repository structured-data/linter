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
schema_base = ENV.fetch("schema_base", "https://raw.githubusercontent.com/schemaorg/schemaorg/master/data/")
schema_version = ENV.fetch("schema_version", "3.6")

namespace :schema do
  desc "Create custom pre-compiled vocabulary"
  task vocab: "lib/rdf/vocab/schema.rb"

  file "lib/rdf/vocab/schema.rb" => :do_build do
    puts "Generate lib/rdf/vocab/schema.rb"
    cmd = "bundle exec rdf"
    cmd += " serialize --uri http://schema.org/ --output-format vocabulary"
    cmd += " --module-name RDF::Vocab"
    cmd += " --class-name SCHEMA"
    cmd += " --strict"
    cmd += " -o lib/rdf/vocab/schema.rb_t"
    cmd += " #{schema_base}/releases/#{schema_version}/all-layers.nq"
    puts "  #{cmd}"
    begin
      %x{#{cmd} && mv lib/rdf/vocab/schema.rb_t lib/rdf/vocab/schema.rb}
    rescue
      puts "Failed to load schema: #{$!.message}"
    ensure
      %x{rm -f lib/rdf/vocab/schema.rb_t}
    end
  end
  task :do_build

  desc "Create pre-compiled context"
  task context: "lib/rdf/vocab/schema_context.rb"
  file "lib/rdf/vocab/schema_context.rb" => :do_build do
    puts "Generate lib/rdf/vocab/schema_context.rb"
    require 'json/ld'
    File.open("lib/rdf/vocab/schema_context.rb", "w") do |f|
      # FIXME: you would think this would be someplace in the data directory
      # schema_base + '/releases/' + schema_version + '/schema.jsonld'
      c = JSON::LD::Context.parse("https://schema.org/", headers: {'Accept' => 'application/ld+json'})
      f.write c.to_rb("http://schema.org/", "http://schema.org", "https://schema.org")
    end
  end

  desc "Create schema example index"
  task :examples do
    %x{rm -rf ./schema.org && mkdir -p ./schema.org/ext/bib ./schema.org/ext/health-lifesci}
    %w(
      examples
      issue-1004-examples
      issue-1100-examples
      sdo-ClaimReview-issue-1061-examples
      sdo-automobile-examples
      sdo-course-examples.txt
      sdo-creativwork-examples
      sdo-datafeed-examples
      sdo-digital-document-examples
      sdo-examples-goodrelations
      sdo-exhibitionevent-examples
      sdo-fibo-examples
      sdo-hotels-examples
      sdo-howto-examples.txt
      sdo-identifier-examples.txt
      sdo-invoice-examples
      sdo-itemlist-examples
      sdo-library-examples
      sdo-lrmi-examples
      sdo-mainEntity-examples
      sdo-map-examples
      sdo-menu-examples
      sdo-music-examples
      sdo-offeredby-examples
      sdo-periodical-examples
      sdo-property-value-examples
      sdo-screeningevent-examples
      sdo-service-examples
      sdo-social-media-examples
      sdo-sponsor-examples
      sdo-sports-examples
      sdo-tourism-examples
      sdo-trip-examples
      sdo-tv-listing-examples
      sdo-userinteraction-examples
      sdo-videogame-examples
      sdo-visualartwork-examples
      sdo-website-examples

      ext/bib/bsdo-agent-examples
      ext/bib/bsdo-atlas-examples
      ext/bib/bsdo-audiobook-examples
      ext/bib/bsdo-chapter-examples
      ext/bib/bsdo-collection-examples
      ext/bib/bsdo-newspaper-examples
      ext/bib/bsdo-thesis-examples
      ext/bib/bsdo-translation-examples
      ext/bib/comics-examples

      ext/health-lifesci/drug-example
      ext/health-lifesci/medicalCondition-example
      ext/health-lifesci/medicalGuideline-example
      ext/health-lifesci/MedicalScholarlyArticle-example
      ext/health-lifesci/medicalWebpage-example
    ).each do |e|
      %x{curl #{schema_base}/#{e}.txt -o ./schema.org/#{e}.txt}
    end
    $:.unshift(File.expand_path("../lib", __FILE__))
    require 'rdf/linter'
    schema = RDF::Linter::Schema.new
    catted = StringIO.new
    Dir.glob(File.expand_path("../schema.org/**/*.txt", __FILE__)).each {|f| catted.write(File.read(f))}
    catted.rewind
    schema.load_examples(catted)
  end

  desc "Generate workings for schema examples"
  task :warnings do
    %x{script/parse schema.org/*.html --lint --quiet -o etc/schema-warnings.txt}
  end
end
