$:.unshift "."
require File.join(File.dirname(__FILE__), 'spec_helper')

describe RDF::Linter, "#lint" do
  include RDF::Linter::Parser

  context "detects undefined vocabulary items" do
    {
      "undefined class" => [
        %(
          @prefix schema: <http://schema.org/> .
          <foo> a schema:NoSuchClass .
        ),
        {
          class: {"schema:NoSuchClass" => ["No class definition found"]},
        }
      ],
      "undefined property" => [
        %(
          @prefix schema: <http://schema.org/> .
          <foo> schema:noSuchProperty "bar" .
        ),
        {
          property: {"schema:noSuchProperty" => ["No property definition found"]},
        }
      ],
    }.each do |name, (input, errors)|
      it name do
        graph = RDF::Graph.new << RDF::Turtle::Reader.new(input)
        expect(RDF::Linter::Parser.lint(graph)).to eq errors
      end
    end
  end

  context "detects domain violations" do
    {
      "type not defined" => [
        %(
          @prefix schema: <http://schema.org/> .
          <foo> schema:acceptedOffer [a schema:Offer] .
        ),
        {
          property: {"schema:acceptedOffer" => ["Subject must have some type defined as domain (schema:Order)"]},
        }
      ],
    }.each do |name, (input, errors)|
      it name do
        graph = RDF::Graph.new << RDF::Turtle::Reader.new(input)
        expect(RDF::Linter::Parser.lint(graph)).to eq errors
      end
    end
  end

  context "detects range violations" do
    {
      "object of wrong type" => [
        %(
          @prefix schema: <http://schema.org/> .
          <foo> a schema:Order; schema:acceptedOffer [a schema:Thing] .
        ),
        {
          property: {"schema:acceptedOffer" => ["Object must have some type defined as range (schema:Offer)"]},
        }
      ],
      "object range with literal" => [
        %(
          @prefix schema: <http://schema.org/> .
          <foo> a schema:Order; schema:acceptedOffer "foo" .
        ),
        {
          property: {"schema:acceptedOffer" => ["Object must have some type defined as range (schema:Offer)"]},
        }
      ],
      "xsd:nonNegativeInteger expected with conforming plain literal" => [
        %(
          @prefix sioc: <http://rdfs.org/sioc/ns#> .
          <foo> sioc:num_authors "bar" .
        ),
        {
          property: {"sioc:num_authors" => ["Object must have some type defined as range (xsd:nonNegativeInteger)"]},
        }
      ],
      "xsd:nonNegativeInteger expected with non-equivalent datatyped literal" => [
        %(
          @prefix sioc: <http://rdfs.org/sioc/ns#> .
          <foo> sioc:num_authors 1 .
        ),
        {
          property: {"sioc:num_authors" => ["Object must have some type defined as range (xsd:nonNegativeInteger)"]},
        }
      ],
      "schema:Text with datatyped literal" => [
        %(
          @prefix schema: <http://schema.org/> .
          @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
          <foo> a schema:Thing; schema:name "foo"^^xsd:token .
        ),
        {
          property: {"schema:name" => ["Object must have some type defined as range (schema:Text)"]},
        }
      ],
      "schema:URL with language-tagged literal" => [
        %(
          @prefix schema: <http://schema.org/> .
          <foo> a schema:Thing; schema:url "http://example/"@en .
        ),
        {
          property: {"schema:url" => ["Object must have some type defined as range (schema:URL)"]},
        }
      ],
      "schema:URL with non-conforming plain literal" => [
        %(
          @prefix schema: <http://schema.org/> .
          <foo> a schema:Thing; schema:url "foo" .
        ),
        {
          property: {"schema:url" => ["Object must have some type defined as range (schema:URL)"]},
        }
      ],
      "schema:Boolean with non-conforming plain literal" => [
        %(
          @prefix schema: <http://schema.org/> .
          <foo> a schema:CreativeWork; schema:isFamilyFriendly "bar" .
        ),
        {
          property: {"schema:isFamilyFriendly" => ["Object must have some type defined as range (schema:Boolean)"]},
        }
      ],
    }.each do |name, (input, errors)|
      it name do
        graph = RDF::Graph.new << RDF::Turtle::Reader.new(input)
        expect(RDF::Linter::Parser.lint(graph)).to eq errors
      end
    end
  end

  context "accepts XSD equivalents for schema.org datatypes" do
    {
      "schema:Text with plain literal" => %(
        @prefix schema: <http://schema.org/> .
        <foo> a schema:Thing; schema:name "bar" .
      ),
      "schema:Text with language-tagged literal" => %(
        @prefix schema: <http://schema.org/> .
        <foo> a schema:Thing; schema:name "bar"@en .
      ),
      "schema:URL with matching plain literal" => %(
        @prefix schema: <http://schema.org/> .
        <foo> a schema:Thing; schema:url "http://example/" .
      ),
      "schema:URL with anyURI" => %(
        @prefix schema: <http://schema.org/> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
        <foo> a schema:Thing; schema:url "http://example/"^^xsd:anyURI .
      ),
      "schema:Boolean with matching plain literal" => %(
        @prefix schema: <http://schema.org/> .
        <foo> a schema:CreativeWork; schema:isFamilyFriendly "true" .
      ),
      "schema:Boolean with boolean" => %(
        @prefix schema: <http://schema.org/> .
        <foo> a schema:CreativeWork; schema:isFamilyFriendly true .
      ),
      "schema:Boolean with schema:True" => %(
        @prefix schema: <http://schema.org/> .
        <foo> a schema:CreativeWork; schema:isFamilyFriendly schema:True .
      ),
      "schema:Boolean with schema:False" => %(
        @prefix schema: <http://schema.org/> .
        <foo> a schema:CreativeWork; schema:isFamilyFriendly schema:False .
      ),
    }.each do |name, input|
      it name do
        graph = RDF::Graph.new << RDF::Turtle::Reader.new(input)
        expect(RDF::Linter::Parser.lint(graph)).to eq Hash.new
      end
    end
  end

  context "accepts alternates when any domainIncludes matches" do
    {
      "one type of several" => %(
        @prefix schema: <http://schema.org/> .
        <foo> a schema:CreativeWork; schema:audience [a schema:Audience] .
      )
    }.each do |name, input|
      it name do
        graph = RDF::Graph.new << RDF::Turtle::Reader.new(input)
        expect(RDF::Linter::Parser.lint(graph)).to eq Hash.new
      end
    end
  end

  context "accepts alternates when any rangeIncludes matches" do
    {
      "one type of several" => %(
        @prefix schema: <http://schema.org/> .
        <foo> a schema:Action; schema:agent [a schema:Person] .
      ),
      "xsd:nonNegativeInteger expected matching datatyped literal" => %(
        @prefix sioc: <http://rdfs.org/sioc/ns#> .
        @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
        <foo> sioc:num_authors "1"^^xsd:nonNegativeInteger .
      ),
      "xsd:nonNegativeInteger expected with conforming plain literal" => %(
        @prefix sioc: <http://rdfs.org/sioc/ns#> .
        <foo> sioc:num_authors "1" .
      ),
    }.each do |name, input|
      it name do
        graph = RDF::Graph.new << RDF::Turtle::Reader.new(input)
        expect(RDF::Linter::Parser.lint(graph)).to eq Hash.new
      end
    end
  end

  shared_examples "Test Case" do |input, expected_errors|
    context File.basename(input) do
      it "has no linter errors" do
        graph = RDF::Graph.load(input)
        graph.query(:predicate => RDF.type) do |statement|
          s = statement.dup
          RDF::Linter::Parser.entailed_types(statement.object).each do |t|
            s.object = t
            graph << s
          end
        end
        expect(RDF::Linter::Parser.lint(graph)).to eq expected_errors
      end
    end
  end

  context "Rich Snippets examples" do
    Dir.glob(File.join(EXAMPLE_DIR, "*.html")) do |input|
      file = input.split('/').last
      expected_errors = {
        "aggregate-reviews.rdfa.html" => {
          :property => {
            "v:votes"=>["No property definition found"]
          }
        },
        "event-multiple.rdfa.html" => {
          :class => {
            "v:Geo"=>["No class definition found"],
            "v:Event"=>["No class definition found"]
          },
          :property => {
            "v:geo"=>["No property definition found"],
            "v:latitude"=>["No property definition found"],
            "v:longitude"=>["No property definition found"],
            "v:url"=>["Subject must have some type defined as domain (v:Person,v:Organization,v:Product,v:Breadcrumb)"],
            "v:summary"=>["Subject must have some type defined as domain (v:Review,v:Recipe)"],
            "v:photo"=>["Subject must have some type defined as domain (rdf:Resource)"],
            "v:startDate"=>["No property definition found"]
          }
        },
        "event.rdfa.html" => {
          :class=>{
            "v:Event"=>["No class definition found"],
            "v:Geo"=>["No class definition found"]
          },
          :property=>{
            "v:url"=>["Subject must have some type defined as domain (v:Person,v:Organization,v:Product,v:Breadcrumb)"],
            "v:summary"=>["Subject must have some type defined as domain (v:Review,v:Recipe)"],
            "v:photo"=>["Subject must have some type defined as domain (rdf:Resource)"],
            "v:description"=>["Subject must have some type defined as domain (v:Review,v:Product)"],
            "v:startDate"=>["No property definition found"],
            "v:endDate"=>["No property definition found"],
            "v:location"=>["No property definition found"],
            "v:eventType"=>["No property definition found"],
            "v:ticket"=>["No property definition found"],
            "v:geo"=>["No property definition found"],
            "v:latitude"=>["No property definition found"],
            "v:longitude"=>["No property definition found"]
          }
        },
        "offer-aggregate.rdfa.html" => {
          :class=>{
            "v:Offer-aggregate"=>["No class definition found"]
          },
          :property=>{
            "v:review"=>["No property definition found"],
            "v:offerDetails"=>["No property definition found"],
            "v:lowPrice"=>["No property definition found"],
            "v:highPrice"=>["No property definition found"],
            "v:currency"=>["Subject must have some type defined as domain (v:Offer,v:OfferAggregate)"]
          }
        },
        "organization.rdfa.html" => {
          :class=>{
            "v:Geo"=>["No class definition found"]
          },
          :property=>{
            "v:geo"=>["No property definition found"],
            "v:latitude"=>["No property definition found"],
            "v:longitude"=>["No property definition found"]
          }
        },
        "product.rdfa.html" => {
          :property=>{
            "v:review"=>["No property definition found"],
            "v:offerDetails"=>["No property definition found"],
            "v:priceValidUntil"=>["No property definition found"]
          }
        },
        "recipe.rdfa.html" => {
          :class=>{
            "v:Nutrition"=>["No class definition found"],
            "v:Ingredient"=>["No class definition found"]
          },
          :property=>{
            "v:review"=>["No property definition found"],
            "v:nutrition"=>["No property definition found"],
            "v:ingredient"=>["No property definition found"],
            "v:instructions"=>["No property definition found"],
            "v:servingSize"=>["Subject must have some type defined as domain (v:nutrition)"],
            "v:calories"=>["Subject must have some type defined as domain (v:nutrition)"],
            "v:fat"=>["Subject must have some type defined as domain (v:nutrition)"],
            "v:name"=>["Subject must have some type defined as domain (rdf:Resource)"],
            "v:amount"=>["Subject must have some type defined as domain (v:ingredient)"]
          }
        }
      }[file]
      it_behaves_like "Test Case", input, expected_errors || {}
    end
  end
end
