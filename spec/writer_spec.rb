#encoding: utf-8
$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/linter/writer'

describe RDF::Linter::Writer do
  include RDF::Linter::Parser

  describe "#rating_helper" do
    {
      %q(@prefix v: <http://rdf.data-vocabulary.org/#> . [ a v:Review-aggregate; v:rating "4"] .) => {
        %(//span[@class='rating-stars']) => true,
        %(//span[@property='v:rating']/@content) => "4.0",
      },
      %q(@prefix v: <http://rdf.data-vocabulary.org/#> .
        [ a v:Review-aggregate;
          v:itemreviewed "Blast 'Em Up";
          v:rating [a v:Rating; v:value "7"; v:best "10"]] .
      ) => {
        %(//span[@class='rating-stars']) => true,
        %(//*[@property='v:value']/@content) => "7",
        %(//*[@property='v:best']/@content) => "10",
      },
      %q(@prefix v: <http://rdf.data-vocabulary.org/#> .
        [ a v:Review-aggregate;
          v:itemreviewed "Blast 'Em Up";
          v:rating [a v:Rating; v:average "88"; v:best "100"];
          v:count "35"] .
      ) => {
        %(//span[@class='rating-stars']) => true,
        %(//*[@property='v:average']/@content) => "88",
        %(//*[@property='v:best']/@content) => "100",
        %(//span[@property='v:count']/text()) => "35",
      },
    }.each do |input, tests|
      context input do
        subject {
          @debug_out = StringIO.new
          logger = Logger.new(@debug_out)
          logger.formatter = lambda {|severity, datetime, progname, msg| "#{msg}\n"}
          parse(:content => input, :format => :ttl, logger: logger).last
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
      %q(@prefix s: <http://schema.org/> . [ a s:Person; s:birthDate "2014-09-01"^^<http://www.w3.org/2001/XMLSchema#date>] .) => {
        %(//span[@property='s:birthDate']/text()) => "Monday, 01 September 2014",
      },
      %q(@prefix s: <http://schema.org/> . [ a s:Person; s:birthDate "2014-09-02Z"^^<http://www.w3.org/2001/XMLSchema#date>] .) => {
        %(//span[@property='s:birthDate']/text()) => "Tuesday, 02 September 2014 UTC",
      },
      %q(@prefix s: <http://schema.org/> . [ a s:Person; s:birthDate "2014-09-03-08:00"^^<http://www.w3.org/2001/XMLSchema#date>] .) => {
        %(//span[@property='s:birthDate']/text()) => "Wednesday, 03 September 2014 PDT",
      },

      # Time
      %q(@prefix s: <http://schema.org/> . [ a s:Person; s:birthDate "12:13:14.567"^^<http://www.w3.org/2001/XMLSchema#time>] .) => {
        %(//span[@property='s:birthDate']/text()) => "12:13:14 PM",
      },
      %q(@prefix s: <http://schema.org/> . [ a s:Person; s:birthDate "12:13:14Z"^^<http://www.w3.org/2001/XMLSchema#time>] .) => {
        %(//span[@property='s:birthDate']/text()) => "12:13:14 PM UTC",
      },
      %q(@prefix s: <http://schema.org/> . [ a s:Person; s:birthDate "12:13:14-08:00"^^<http://www.w3.org/2001/XMLSchema#time>] .) => {
        %(//span[@property='s:birthDate']/text()) => "12:13:14 PM PDT",
      },

      # DateTime
      %q(@prefix s: <http://schema.org/> . [ a s:Person; s:birthDate "2014-09-01T12:13:14.567"^^<http://www.w3.org/2001/XMLSchema#dateTime>] .) => {
        %(//span[@property='s:birthDate']/text()) => "12:13:14 PM on Monday, 01 September 2014",
      },
      %q(@prefix s: <http://schema.org/> . [ a s:Person; s:birthDate "2014-09-01T12:13:14.567Z"^^<http://www.w3.org/2001/XMLSchema#dateTime>] .) => {
        %(//span[@property='s:birthDate']/text()) => "12:13:14 PM UTC on Monday, 01 September 2014",
      },
      %q(@prefix s: <http://schema.org/> . [ a s:Person; s:birthDate "2014-09-01T12:13:14.567-08:00"^^<http://www.w3.org/2001/XMLSchema#dateTime>] .) => {
        %(//span[@property='s:birthDate']/text()) => "12:13:14 PM PDT on Monday, 01 September 2014",
      },
    }.each do |input, tests|
      context input do
        subject {
          @debug_out = StringIO.new
          logger = Logger.new(@debug_out)
          logger.formatter = lambda {|severity, datetime, progname, msg| "#{msg}\n"}
          parse(:content => input, :format => :ttl, logger: logger).last
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
