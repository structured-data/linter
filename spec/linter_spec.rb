$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')

describe RDF::Linter do
  include RDF::Linter::Parser

  # Read input files, parse, generate HTML+RDFa output and compare
  # with expected result
  context "Snippet Generation" do
    Dir.glob(File.join(TEST_DIR, "*_in.html")) do |input|
      it "parses #{input}" do
        file = File.open(input)
        res = File.read(input.sub("_in", "_res"))
        type, content = parse(:tempfile => file, :format => :all)
        content.should == res
      end
    end
  end
end