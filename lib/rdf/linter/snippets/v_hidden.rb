# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Geo" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Geo" => "http://data-vocabulary.org/",
    "http://rdf.data-vocabulary.org/#Ingredient" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Ingredient" => "http://data-vocabulary.org/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {}
    })
  end
end