$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'csv'

describe RDF::Linter do
  include RDF::Linter::Parser

  before(:each) do
    $debug_output = StringIO.new()
    $logger = Logger.new($debug_output)
    $logger.formatter = lambda {|severity, datetime, progname, msg| "#{msg}\n"}
  end

  shared_examples "Test Case" do |input, csv|
    context File.basename(input) do
      before(:all) {
        @subject, @debug = parse(input)
      }
      if File.exist?(csv)
        CSV.foreach(csv) do |(xpath, result)|
          next if xpath =~ /^\s*#/
          result = case result
          when /^\s*true\s*$/i    then true
          when /^\s*false\s*$/i   then false
          when /^\/(.*)\/$/  then Regexp.new($1)
          else result.to_s
          end

          it "has path #{xpath.inspect} matching #{result.inspect}" do
            expect(@subject).to have_xpath(xpath.to_s, result, @debug << $debug_output)
          end
        end
      else
        it "parses, but has no matchers" do
          expect(@subject).to have_xpath("//div", true)
        end
      end
    end
  end

  # Read input files, parse, generate HTML+RDFa output and compare
  # with XPath results in associated CSV file
  # The CSV file is composed of two columns, the first is an XPath,
  # and the second is a matcher, which is evaluated in Ruby to a String,
  # Regexp, TrueClass, or FalseClass
  context "Test Cases" do
    Dir.glob(File.join(TEST_DIR, "*.html")) do |input|
      csv = input.sub('.html', '.csv')
      it_behaves_like "Test Case", input, csv
    end
  end

  context "Snippet Generation" do
    (
      Dir.glob(File.join(EXAMPLE_DIR, "*.{html,rdfa,md}")) +
      Dir.glob(File.join(SCHEMA_DIR, "**/*.{html,rdfa,md}"))
    ).each do |input|
      csv = File.join(TEST_DIR, File.basename(input.sub('.html', '.csv')))
      it_behaves_like "Test Case", input, csv
    end
  end

  def parse(input)
    $parser_spec_results ||= {}
    $parser_spec_results[input] ||= begin
      debug = []
      [RDF::Linter::Parser.parse(:content => File.open(input), :format => :all, :debug => debug).last, debug]
    end
  end
end