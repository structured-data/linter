# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Geo" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Geo" => "http://data-vocabulary.org/",
    "http://rdf.data-vocabulary.org/#Ingredient" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Ingredient" => "http://data-vocabulary.org/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :identifier => type,
        # Priority of this snippet when multiple are matched. If it's missing, it's assumed to be 99
        # When multiple snippets are matched by an object, the one with the highest priority wins.
        :priority => 5,
      }
    })
  end
end