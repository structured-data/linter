require 'rubygems'

namespace :doc do
  begin
    require 'yard'

    YARD::Rake::YardocTask.new
  rescue LoadError
  end
end

desc "Create schema example index"
task :schema_examples do
  %x{rm -rf ./schema.org && mkdir ./schema.org}
  %w(examples sdo-map-examples sdo-website-examples).each do |e|
    %x{curl https://raw.githubusercontent.com/rvguha/schemaorg/master/data/#{e}.txt -o ./schema.org/#{e}.txt}
  end
  $:.unshift(File.expand_path("../lib", __FILE__))
  require 'rdf/linter'
  schema = RDF::Linter::Schema.new
  catted = StringIO.new
  Dir.glob(File.expand_path("../schema.org/*examples.txt", __FILE__)).each {|f| catted.write(File.read(f))}
  catted.rewind
  schema.load_examples(catted)
end
