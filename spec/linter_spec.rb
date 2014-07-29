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
        expect(RDF::Linter::Parser.lint(graph)).to have_errors errors
      end
    end
  end

  context "detects domain violations" do
    {
      "type not defined" => [
        %(
          @prefix schema: <http://schema.org/> .
          <foo> a schema:Person; schema:acceptedOffer [a schema:Offer] .
        ),
        {
          property: {"schema:acceptedOffer" => [/Subject .* not compatible with domainIncludes \(schema:Order\)/]},
        }
      ],
    }.each do |name, (input, errors)|
      it name do
        graph = RDF::Graph.new << RDF::Turtle::Reader.new(input)
        expect(RDF::Linter::Parser.lint(graph)).to have_errors errors
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
          property: {"schema:acceptedOffer" => [/Object .* not compatible with rangeIncludes \(schema:Offer\)/]},
        }
      ],
      #"object range with literal" => [
      #  %(
      #    @prefix schema: <http://schema.org/> .
      #    <foo> a schema:Order; schema:acceptedOffer "foo" .
      #  ),
      #  {
      #    property: {"schema:acceptedOffer" => [/Object .* not compatible with rangeIncludes \(schema:Offer\)/]},
      #  }
      #],
      "xsd:nonNegativeInteger expected with conforming plain literal" => [
        %(
          @prefix sioc: <http://rdfs.org/sioc/ns#> .
          <foo> sioc:num_authors "bar" .
        ),
        {
          property: {"sioc:num_authors" => [/Object .* not compatible with range \(xsd:nonNegativeInteger\)/]},
        }
      ],
      "xsd:nonNegativeInteger expected with non-equivalent datatyped literal" => [
        %(
          @prefix sioc: <http://rdfs.org/sioc/ns#> .
          <foo> sioc:num_authors 1 .
        ),
        {
          property: {"sioc:num_authors" => [/Object .* not compatible with range \(xsd:nonNegativeInteger\)/]},
        }
      ],
      "schema:Text with datatyped literal" => [
        %(
          @prefix schema: <http://schema.org/> .
          @prefix xsd: <http://www.w3.org/2001/XMLSchema#> .
          <foo> a schema:Thing; schema:name "foo"^^xsd:token .
        ),
        {
          property: {"schema:name" => [/Object .* not compatible with rangeIncludes \(schema:Text\)/]},
        }
      ],
      "schema:URL with language-tagged literal" => [
        %(
          @prefix schema: <http://schema.org/> .
          <foo> a schema:Thing; schema:url "http://example/"@en .
        ),
        {
          property: {"schema:url" => [/Object .* not compatible with rangeIncludes \(schema:URL\)/]},
        }
      ],
      "schema:URL with non-conforming plain literal" => [
        %(
          @prefix schema: <http://schema.org/> .
          <foo> a schema:Thing; schema:url "foo" .
        ),
        {
          property: {"schema:url" => [/Object .* not compatible with rangeIncludes \(schema:URL\)/]},
        }
      ],
      "schema:Boolean with non-conforming plain literal" => [
        %(
          @prefix schema: <http://schema.org/> .
          <foo> a schema:CreativeWork; schema:isFamilyFriendly "bar" .
        ),
        {
          property: {"schema:isFamilyFriendly" => [/Object .* not compatible with rangeIncludes \(schema:Boolean\)/]},
        }
      ],
    }.each do |name, (input, errors)|
      it name do
        graph = RDF::Graph.new << RDF::Turtle::Reader.new(input)
        expect(RDF::Linter::Parser.lint(graph)).to have_errors errors
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
          RDF::Reasoner.apply(:rdfs, :schema)
          RDF::Linter::Parser.entailed_types(statement.object).each do |t|
            s.object = t
            graph << s
          end
        end
        expect(RDF::Linter::Parser.lint(graph)).to have_errors expected_errors
      end
    end
  end

  context "Rich Snippets examples" do
    Dir.glob(File.join(EXAMPLE_DIR, "*.html")) do |input|
      file = input.split('/').last
      expected_errors = {
        "aggregate-reviews.md.html" => {
          :property => {
            "vmd:votes"=>["No property definition found"]
          }
        },
        "aggregate-reviews.rdfa.html" => {
          :property => {
            "v:votes"=>["No property definition found"]
          }
        },
        "event-multiple.md.html" => {
          :class => {
            "vmd:Geo"=>["No class definition found"],
            "vmd:Event"=>["No class definition found"]
          },
          :property => {
            "vmd:geo"=>["No property definition found"],
            "vmd:latitude"=>["No property definition found"],
            "vmd:longitude"=>["No property definition found"],
            "vmd:startDate"=>["No property definition found"]
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
            "v:startDate"=>["No property definition found"]
          }
        },
        "event.md.html" => {
          :class=>{
            "vmd:Event"=>["No class definition found"],
            "vmd:Geo"=>["No class definition found"]
          },
          :property=>{
            "vmd:startDate"=>["No property definition found"],
            "vmd:endDate"=>["No property definition found"],
            "vmd:location"=>["No property definition found"],
            "vmd:eventType"=>["No property definition found"],
            "vmd:ticket"=>["No property definition found"],
            "vmd:geo"=>["No property definition found"],
            "vmd:latitude"=>["No property definition found"],
            "vmd:longitude"=>["No property definition found"],
            "vmd:priceValidUntil"=>["No property definition found"]
          }
        },
        "event.rdfa.html" => {
          :class=>{
            "v:Event"=>["No class definition found"],
            "v:Geo"=>["No class definition found"]
          },
          :property=>{
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
        "offer-aggregate.md.html" => {
          :class=>{
            "vmd:Offer-aggregate"=>["No class definition found"]
          },
          :property=>{
            "vmd:review"=>["No property definition found"],
            "vmd:offerDetails"=>["No property definition found"],
            "vmd:lowPrice"=>["No property definition found"],
            "vmd:highPrice"=>["No property definition found"],
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
        "product.md.html" => {
          :property=>{
            "vmd:review"=>["No property definition found"],
            "vmd:offerDetails"=>["No property definition found"],
            "vmd:priceValidUntil"=>["No property definition found"]
          }
        },
        "product.rdfa.html" => {
          :property=>{
            "v:review"=>["No property definition found"],
            "v:offerDetails"=>["No property definition found"],
            "v:priceValidUntil"=>["No property definition found"]
          }
        },
        "recipe.md.html" => {
          :property=>{
            "vmd:review"=>["No property definition found"],
            "vmd:instructions"=>[/Object .* not compatible with range \(vmd:Instructions\)/],
          }
        },
        "recipe.rdfa.html" => {
          :property=>{
            "v:review"=>["No property definition found"],
            "v:instructions"=>[/Object .* not compatible with range \(v:Instructions\)/],
          }
        }
      }[file]
      it_behaves_like "Test Case", input, expected_errors || {}
    end
  end

  context "Role intermediaries" do
    {
      "Cryptography Users" => {
        input: %(
          @prefix schema: <http://schema.org/> .
          <foo> a schema:Organization;
            schema:name "Cryptography Users";
            schema:member [
              a schema:OrganizationRole;
              schema:member [
                a schema:Person;
                schema:name "Alice"
              ];
              schema:startDate "1977"
            ] .
        ),
        expected_errors: {}
      },
      "Inconsistent properties" => {
        input: %(
          @prefix schema: <http://schema.org/> .
          <foo> a schema:Organization;
            schema:name "Cryptography Users";
            schema:member [
              a schema:OrganizationRole;
              schema:alumni [
                a schema:Person;
                schema:name "Alice"
              ];
              schema:startDate "1977"
            ] .
        ),
        expected_errors: {
          property: {
            "schema:member" => [/Object .* not compatible with rangeIncludes \(schema:Organization,schema:Person\)/],
            "schema:alumni"=> [/Subject .* not compatible with domainIncludes \(schema:EducationalOrganization\)/]
          }
        }
      },
    }.each do |name, params|
      it name do
        graph = RDF::Graph.new << RDF::Turtle::Reader.new(params[:input])
        graph.query(:predicate => RDF.type) do |statement|
          s = statement.dup
          RDF::Reasoner.apply(:rdfs, :schema)
          RDF::Linter::Parser.entailed_types(statement.object).each do |t|
            s.object = t
            graph << s
          end
        end
        expect(RDF::Linter::Parser.lint(graph)).to have_errors params[:expected_errors]
      end
    end
  end
end
