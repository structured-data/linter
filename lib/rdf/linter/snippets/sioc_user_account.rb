# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdfs.org/sioc/ns#UserAccount" => "http://rdfs.org/sioc/ns#",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        # Properties to be used in snippet title
        :title_props => ["http://xmlns.com/foaf/0.1/name"],
        :nested_props => ["http://xmlns.com/foaf/0.1/name"],
      }
    })
  end
end

