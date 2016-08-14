require 'rubygems'

namespace :doc do
  begin
    require 'yard'

    YARD::Rake::YardocTask.new
  rescue LoadError
  end
end

namespace :schema do
  desc "Create schema example index"
  task :examples do
    #%x{rm -rf ./schema.org && mkdir -p ./schema.org/ext/bib ./schema.org/ext/health-lifesci}
    %w(
      examples
      sdo-automobile-examples
      sdo-creativwork-examples
      sdo-datafeed-examples
      sdo-digital-document-examples
      sdo-examples-goodrelations
      sdo-exhibitionevent-examples
      sdo-fibo-examples
      sdo-hotels-examples
      sdo-invoice-examples
      sdo-itemlist-examples
      sdo-library-examples
      sdo-lrmi-examples
      sdo-mainEntity-examples
      sdo-map-examples
      sdo-music-examples
      sdo-offeredby-examples
      sdo-periodical-examples
      sdo-property-value-examples
      sdo-screeningevent-examples
      sdo-service-examples
      sdo-social-media-examples
      sdo-sponsor-examples
      sdo-sports-examples
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
      ext/health-lifesci/physical-activity-and-exercise
    ).each do |e|
      #%x{curl https://raw.githubusercontent.com/schemaorg/schemaorg/master/data/#{e}.txt -o ./schema.org/#{e}.txt}
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
