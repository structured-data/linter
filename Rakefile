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
schema_version = ENV.fetch("schema_version", "11.0")

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
      sdo-airport-examples.txt
      sdo-apartment-examples.txt
      sdo-automobile-examples
      sdo-book-series-examples.txt
      sdo-bus-stop-examples.txt
      sdo-ClaimReview-issue-1061-examples
      sdo-course-examples.txt
      sdo-creativwork-examples
      sdo-datafeed-examples
      sdo-defined-region-examples.txt
      sdo-dentist-examples.txt
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
      sdo-offer-shipping-details-examples.txt
      sdo-offeredby-examples
      sdo-periodical-examples
      sdo-police-station-examples.txt
      sdo-property-value-examples
      sdo-screeningevent-examples
      sdo-service-examples
      sdo-single-family-residence-examples.txt
      sdo-social-media-examples
      sdo-sponsor-examples
      sdo-sports-examples
      sdo-tourism-examples
      sdo-train-station-examples.txt
      sdo-trip-examples
      sdo-tv-listing-examples
      sdo-userinteraction-examples
      sdo-videogame-examples
      sdo-visualartwork-examples
      sdo-website-examples

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
