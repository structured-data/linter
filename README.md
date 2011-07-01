# RDF Linter

Extract and validate embedded RDF markup in HTML and other formats.

## DESCRIPTION

## FEATURES
Distills between formats supported in [Linked Data][linkeddata].

* Includes [N-Triples][] support using [RDF.rb][].
* Includes [RDF/XML][] support using the [RDF::RDFXML][] gem.
* Includes [Turtle][] and [Notation3][] support using the [RDF::N3][] gem.
* Includes [RDFa][] support using the [RDF::RDFa][] gem.
* Includes [RDF/JSON][] support using the [RDF::JSON][] gem.
* Includes [TriX][] support using the [RDF::TriX][] gem.
* Includes [Microdata][] support using the [RDF::Microdata][] gem.
* Includes [JSON-LD][] support using the [JSON::LD][] gem.

## Dependencies
* [RDF.rb](http://rubygems.org/gems/rdf) (>= 0.3.3)
* [Linked Data](http://rubygems.org/gems/linkeddata) (>= 0.3.2)
* [Linked Data for Rack](http://rubygems.org/gems/rack-linkeddata) (>= 0.3.1)
* [Linked Data for Sinatra](http://rubygems.org/gems/sinatra-linkeddata) (>= 0.3.1)
* [Nokogiri](http://rubygems.org/gems/nokogiri) (>= 1.4.4)
* [RDF::JSON](http://rubygems.org/gems/rdf-json) (>= 0.3.1)
* [RDF::Microdata](http://rubygems.org/gems/rdf-microdata) (>= 0.1.0)
* [RDF::N3](http://rubygems.org/gems/rdf-n3) (>= 0.3.3)
* [RDF::RDFa](http://rubygems.org/gems/rdf-rdfa) (>= 0.3.3)
* [RDF::RDFXML](http://rubygems.org/gems/rdf-rdfxml) (>= 0.3.3)
* [RDF::TriX](http://rubygems.org/gems/rdf-trix) (>= 0.3.1)
* [JSON::LD](http://rubygems.org/gems/json-ld) (>= 0.0.4)

## AUTHOR
* [Gregg Kellogg](http://github.com/gkellogg) - <http://kellogg-assoc.com/>
* Stéphane Corlosquet

## Setup notes
* public/.htaccess
* Bundle installed using:

    bundle install --path vendor/bundler

* Start the server with:

    bundle exec shotgun -p 3000 config.ru

## FEEDBACK

[JSON-LD]:        http://json-ld.org/spec/latest/
[linkeddata]:     {file:linkeddata-README}
[Microdata]:      http://dev.w3.org/html5/md/
[N-Triples]:      http://en.wikipedia.org/wiki/N-Triples
[Notation3]:      http://en.wikipedia.org/wiki/Notation3
[RDF/JSON]:       http://n2.talis.com/wiki/RDF_JSON_Specification
[RDF/XML]:        http://www.w3.org/TR/rdf-syntax-grammar/
[RDFa]:           http://en.wikipedia.org/wiki/RDFa
[TriX]:           http://en.wikipedia.org/wiki/TriX_(syntax)
[Turtle]:         http://en.wikipedia.org/wiki/Turtle_(syntax)
