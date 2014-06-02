$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')
require 'rdf/rdfa'
require 'rdf/rdfxml'
require 'rdf/n3'
require 'rdf/microdata'

describe RDF::All::Reader do
  # Check format detection
  describe ".detect" do
    [
      ["rdfa", %q(
        <html profile="foo">
          <body>
            <div property="foo" resource="#me"/>
          </body>
        </html>
      )],
      ["rdfxml", %q(
      <rdf:RDF xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#">
        <rdf:Description about="#me">
        </rdf:Description>
      </rdf:RDF>
      )],
      ["microdata", %q(
        <dl itemscope
            itemtype="http://purl.org/vocab/frbr/core#Work"
            itemid="http://books.example.com/works/45U8QJGZSQKDH8N">
        </dl>
      )],
      ["turtle:ttl", %q(
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
      )],
      ["rdfa:microdata", %q(
      <html @profile="foo">
        <body>
          <dl about="#work" itemscope
              itemtype="http://purl.org/vocab/frbr/core#Work"
              itemid="http://books.example.com/works/45U8QJGZSQKDH8N">
          </dl>
        </body>
      </html>
      )],
      # A problematic case, as the preamble is so long
      [
        "rdfa", %q(
        <!DOCTYPE html PUBLIC "-//W3C//DTD XHTML+RDFa 1.0//EN" "http://www.w3.org/MarkUp/DTD/xhtml-rdfa-1.dtd">
        <html
          xmlns="http://www.w3.org/1999/xhtml"
          xmlns:xsd="http://www.w3.org/2001/XMLSchema#"
          xmlns:wdrs="http://www.w3.org/2007/05/powder-s#"
          xmlns:void="http://rdfs.org/ns/void#"
          xmlns:vcard="http://www.w3.org/2006/vcard/ns#"
          xmlns:unit="http://www.w3.org/2007/ont/unit#"
          xmlns:udaprices="http://uda.openlinksw.com/pricing/#"
          xmlns:skos="http://www.w3.org/2004/02/skos/core#"
          xmlns:sioc="http://rdfs.org/sioc/ns#"
          xmlns:rss="http://purl.org/rss/1.0"
          xmlns:rf="http://ontologi.es/rail/vocab#facilities/"
          xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
          xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
          xmlns:rail="http://ontologi.es/rail/vocab#"
          xmlns:owl="http://www.w3.org/2002/07/owl#"
          xmlns:ovterms="http://open.vocab.org/terms/"
          xmlns:oplweb="http://data.openlinksw.com/oplweb#"
          xmlns:openlink="http://www.openlinksw.com/oplweb#"
          xmlns:og="http://ogp.me/ns#"
          xmlns:gr="http://purl.org/goodrelations/v1#"
          xmlns:geo="http://www.w3.org/2003/01/geo/wgs84_pos#"
          xmlns:foaf="http://xmlns.com/foaf/0.1/"
          xmlns:exif="http://www.kanzaki.com/ns/exif"
          xmlns:doap="http://usefulinc.com/ns/doap#"
          xmlns:dcterms="http://purl.org/dc/terms/"
          xmlns:dc="http://purl.org/dc/elements/1.1/"
          xmlns:ctag="http://commontag.org/ns#"
          xmlns:cc="http://creativecommons.org/licenses/"
          xmlns:bibo="http://purl.org/ontology/bibo/"
          xmlns:atomowl="http://bblfish.net/work/atom-owl/2006-06-06/#">
        <head>
          <meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
          <title>OpenLink ODBC, JDBC, ADO.NET, OLEDB Special Offers Price List</title>
          <meta property="og:url" content="http://uda.openlinksw.com/pricing/" />
        </head>
        </html>
        )
      ],
    ].each do |(format, sample)|
      it "detects #{format}" do
        detected = RDF::Format.
          each.
          to_a.
          select {|f| f.detect(sample)}.
          compact.
          map(&:to_sym).
          map(&:to_s).
          join(":")
        expect(detected).to eql format
      end
    end
  end
end