# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdfs.org/sioc/ns#UserAccount" => "http://rdfs.org/sioc/ns#",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :identifier => "sioc:UserAccount",
        :priority => 99,
      }
    })
  end
end

