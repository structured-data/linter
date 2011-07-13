$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'csv'
require 'fastercsv' if CSV.const_defined?(:Reader)  # For Ruby 1.8

describe RDF::Linter do
  include RDF::Linter::Parser

  # Read input files, parse, generate HTML+RDFa output and compare
  # with XPath results in associated CSV file
  # The CSV file is composed of two columns, the first is an XPath,
  # and the second is a matcher, which is evaluated in Ruby to a String,
  # Regexp, TrueClass, or FalseClass
  context "Test Cases" do
    Dir.glob(File.join(TEST_DIR, "*.html")) do |input|
      context File.basename(input) do
        subject {
          type, content = parse(:content => File.open(input), :format => :all)
          content
        }
        csv = input.sub('.html', '.csv')
        if File.exist?(csv)
          csv_class = CSV.const_defined?(:Reader) ? FasterCSV : CSV
          csv_class.foreach(csv) do |(xpath,result)|
            next if xpath =~ /^\s*#/
            result = case result
            when /^\s*true\s*$/i    then true
            when /^\s*false\s*$/i   then false
            when /^\/(.*)\/$/  then Regexp.new($1)
            else result.to_s
            end

            it "has path #{xpath.inspect} matching #{result.inspect}" do
              subject.should have_xpath(xpath, result)
            end
          end
        else
          it "parses, but has no matchers" do
            pending("Implement matchers")
          end
        end
      end
    end
  end

  context "Snippet Generation" do
    Dir.glob(File.join(EXAMPLE_DIR, "*.html")) do |input|
      context File.basename(input) do
        subject {
          type, content = parse(:content => File.open(input), :format => :all)
          content
        }
        csv = File.join(TEST_DIR, File.basename(input.sub('.html', '.csv')))
        if File.exist?(csv)
          CSV.foreach(csv) do |(xpath,result)|
            next if xpath =~ /^\s*#/
            result = case result
            when /^\s*true\s*$/i    then true
            when /^\s*false\s*$/i   then false
            when /^\/(.*)\/$/  then Regexp.new($1)
            else result.to_s
            end

            it "has path #{xpath.inspect} matching #{result.inspect}" do
              subject.should have_xpath(xpath, result)
            end
          end
        else
          it "parses, but has no matchers" do
            pending("Implement matchers")
          end
        end
      end
    end
  end
end