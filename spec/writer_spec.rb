#encoding: utf-8
$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/linter/writer'

describe RDF::Linter::Writer do
  include RDF::Linter::Parser

  describe "#rating_helper" do
    {
      %q(@prefix v: <http://rdf.data-vocabulary.org/#> . [ a v:Review-aggregate; v:rating "4"] .) => {
        %(//span[@class='star-rating']) => true,
        %(//span[@class='star-rating']/i[1]/@class) => "star",
        %(//span[@class='star-rating']/i[2]/@class) => "star",
        %(//span[@class='star-rating']/i[3]/@class) => "star",
        %(//span[@class='star-rating']/i[4]/@class) => "star",
        %(//span[@class='star-rating']/i[5]/@class) => false,
      },
    }.each do |input, tests|
      context input do
        subject {
          @debug_out = StringIO.new
          logger = Logger.new(@debug_out)
          logger.formatter = lambda {|severity, datetime, progname, msg| "#{msg}\n"}
          graph = RDF::Graph.new << RDF::Turtle::Reader.new(input)
          RDF::Linter::Writer.buffer {|w| w << graph}
        }
        
        tests.each do |xpath, result|
          it "has path #{xpath.inspect} matching #{result.inspect}" do
            expect(subject).to have_xpath(xpath.to_s, result, [@debug_out.read])
          end
        end
      end
    end
  end

  context "dates and times" do
    {
      # Date
      %q([ a schema:Person; schema:birthDate "2014-09-01"^^<http://www.w3.org/2001/XMLSchema#date>] .) => {
        %(//span[@property='schema:birthDate']/text()) => "Monday, 01 September 2014",
      },
      %q([ a schema:Person; schema:birthDate "2014-09-02Z"^^<http://www.w3.org/2001/XMLSchema#date>] .) => {
        %(//span[@property='schema:birthDate']/text()) => "Tuesday, 02 September 2014 UTC",
      },
      %q([ a schema:Person; schema:birthDate "2014-09-03-08:00"^^<http://www.w3.org/2001/XMLSchema#date>] .) => {
        %(//span[@property='schema:birthDate']/text()) => %r(Wednesday, 03 September 2014 P[SD]T),
      },

      # Time
      %q([ a schema:Person; schema:birthDate "12:13:14.567"^^<http://www.w3.org/2001/XMLSchema#time>] .) => {
        %(//span[@property='schema:birthDate']/text()) => "12:13:14 PM",
      },
      %q([ a schema:Person; schema:birthDate "12:13:14Z"^^<http://www.w3.org/2001/XMLSchema#time>] .) => {
        %(//span[@property='schema:birthDate']/text()) => "12:13:14 PM UTC",
      },
      %q([ a schema:Person; schema:birthDate "12:13:14-08:00"^^<http://www.w3.org/2001/XMLSchema#time>] .) => {
        %(//span[@property='schema:birthDate']/text()) => %r(12:13:14 PM P[SD]T),
      },

      # DateTime
      %q([ a schema:Person; schema:birthDate "2014-09-01T12:13:14.567"^^<http://www.w3.org/2001/XMLSchema#dateTime>] .) => {
        %(//span[@property='schema:birthDate']/text()) => "12:13:14 PM on Monday, 01 September 2014",
      },
      %q([ a schema:Person; schema:birthDate "2014-09-01T12:13:14.567Z"^^<http://www.w3.org/2001/XMLSchema#dateTime>] .) => {
        %(//span[@property='schema:birthDate']/text()) => "12:13:14 PM UTC on Monday, 01 September 2014",
      },
      %q([ a schema:Person; schema:birthDate "2014-09-01T12:13:14.567-08:00"^^<http://www.w3.org/2001/XMLSchema#dateTime>] .) => {
        %(//span[@property='schema:birthDate']/text()) => %r(12:13:14 PM P[SD]T on Monday, 01 September 2014),
      },
    }.each do |input, tests|
      context input do
        subject {
          @debug_out = StringIO.new
          logger = Logger.new(@debug_out)
          logger.formatter = lambda {|severity, datetime, progname, msg| "#{msg}\n"}
          graph = RDF::Graph.new << RDF::Turtle::Reader.new("@prefix schema: <http://schema.org/> . #{input}")
          RDF::Linter::Writer.buffer {|w| w << graph}
        }
        
        tests.each do |xpath, result|
          it "has path #{xpath.inspect} matching #{result.inspect}" do
            expect(subject).to have_xpath(xpath.to_s, result, [@debug_out.read])
          end
        end
      end
    end
  end
end
