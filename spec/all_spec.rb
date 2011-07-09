$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/rdfa'
require 'rdf/rdfxml'
require 'rdf/n3'
require 'rdf/microdata'
require 'json/ld'

describe RDF::All::Reader do
  # Check format detection
  describe ".detect" do
    {
      "rdfa:microdata" => %q(
        <html @profile="foo">
          <body>
            <div about="#me"/>
          </body>
        </html>
      ),
      "rdfxml" => %q(
      <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description about="#me">
        </rdf:Description>
      </rdf:RDF>
      ),
      "rdfa:microdata" => %q(
        <dl itemscope
            itemtype="http://purl.org/vocab/frbr/core#Work"
            itemid="http://books.example.com/works/45U8QJGZSQKDH8N">
        </dl>
      ),
      "n3" => %q(
        @prefix dc: <http://purl.org/dc/elements/1.1/> .
        @prefix dcterms: <http://purl.org/dc/terms/> .
        @prefix rdf:  <http://www.w3.org/1999/02/22-rdf-syntax-ns#> .
        @prefix rdfs: <http://www.w3.org/2000/01/rdf-schema#> .
        @prefix swrc: <http://swrc.ontoware.org/ontology#> .
        @prefix foaf: <http://xmlns.com/foaf/0.1/> .
        @prefix bench: <http://localhost/vocabulary/bench/> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
        @prefix person: <http://localhost/persons/> .
        bench:Journal rdfs:subClassOf foaf:Document.
        bench:Proceedings rdfs:subClassOf foaf:Document.
        bench:Inproceedings rdfs:subClassOf foaf:Document.
      ),
      "ld" => %q(
        {
          "@context": "http://example.org/Person",
          "@subject": "http://greggkellogg.net/foaf#me",
          "@type": ["Person", "Developer"],
          "name": "Gregg Kellogg"
        }
      ),
      "rdfa:microdata" => %q(
      <html @profile="foo">
        <body>
          <dl about="#work" itemscope
              itemtype="http://purl.org/vocab/frbr/core#Work"
              itemid="http://books.example.com/works/45U8QJGZSQKDH8N">
          </dl>
        </body>
      </html>
      ),
    }.each do |format, sample|
      it "detects #{format}" do
        detected = RDF::Reader.
          each.
          to_a.
          select {|r| r.detect(sample)}.
          compact.
          map(&:to_sym).
          map(&:to_s).
          join(":")
        detected.should == format
      end
    end
  end
end