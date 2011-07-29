# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://www.w3.org/2004/02/skos/core#Concept" => "http://www.w3.org/2004/02/skos/core#",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        # Properties to be used in snippet title
        :title_props => ["http://www.w3.org/2004/02/skos/core#prefLabel"],
        :nested_props => ["http://www.w3.org/2004/02/skos/core#prefLabel"],
      }
    })
  end
end

