# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://www.w3.org/2004/02/skos/core#Concept" => "http://www.w3.org/2004/02/skos/core#",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :identifier => "skos:Concept",
        # Properties to be used in snippet title
        :title_props => ["http://www.w3.org/2004/02/skos/core#prefLabel"],
        :nested_props => ["http://www.w3.org/2004/02/skos/core#prefLabel"],
        # Priority of this snippet when multiple are matched. If it's missing, it's assumed to be 99
        # When multiple snippets are matched by an object, the one with the highest priority wins.
        :priority => 20,
      }
    })
  end
end

