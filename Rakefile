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
  %x{curl https://raw.githubusercontent.com/rvguha/schemaorg/master/data/examples.txt -o ./schema.org/examples.txt}
  $:.unshift(File.expand_path("../lib", __FILE__))
  require 'rdf/linter'
  schema = RDF::Linter::Schema.new
  schema.load_examples(File.expand_path("../schema.org/examples.txt", __FILE__))
end
