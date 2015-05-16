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
    %x{rm -rf ./schema.org && mkdir ./schema.org}
    %w(
      examples
      sdo-automobile-examples
      sdo-invoice-examples
      sdo-itemlist-examples
      sdo-mainEntity-examples
      sdo-map-examples
      sdo-music-examples
      sdo-periodical-examples
      sdo-property-examples
      sdo-screeningevent-examples
      sdo-sports-examples
      sdo-tv-listing-examples
      sdo-videogame-examples
      sdo-visualartwork-examples
      sdo-website-examples
    ).each do |e|
      %x{curl https://raw.githubusercontent.com/schemaorg/schemaorg/master/data/#{e}.txt -o ./schema.org/#{e}.txt}
    end
    $:.unshift(File.expand_path("../lib", __FILE__))
    require 'rdf/linter'
    schema = RDF::Linter::Schema.new
    catted = StringIO.new
    Dir.glob(File.expand_path("../schema.org/*examples.txt", __FILE__)).each {|f| catted.write(File.read(f))}
    catted.rewind
    schema.load_examples(catted)
  end

  desc "Generate workings for schema examples"
  task :warnings do
    %x{script/parse schema.org/*.html --lint --quiet -o etc/schema-warnings.txt}
  end
end
