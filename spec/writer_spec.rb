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
        %(//*[@property='v:value']/text()) => "7",
        %(//*[@property='v:best']/text()) => "10",
      },
      %q(@prefix v: <http://rdf.data-vocabulary.org/#> .
        [ a v:Review-aggregate;
          v:itemreviewed "Blast 'Em Up";
          v:rating [a v:Rating; v:average "88"; v:best "100"];
          v:count "35"] .
      ) => {
        %(//span[@class='rating-stars']) => true,
        %(//*[@property='v:average']/text()) => "88",
        %(//*[@property='v:best']/text()) => "100",
        %(//span[@property='v:count']/text()) => "35",
      },
    }.each do |input, tests|
      context input do
        subject {
          parse(:content => input, :format => :ttl).last
        }
        
        tests.each do |xpath, result|
          it "has path #{xpath.inspect} matching #{result.inspect}" do
            subject.should have_xpath(xpath.to_s, result)
          end
        end
      end
    end
  end
end