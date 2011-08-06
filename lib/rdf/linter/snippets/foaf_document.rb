# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://xmlns.com/foaf/0.1/Document" => "http://xmlns.com/foaf/0.1/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :identifier => "foaf:Document",
        # Properties to be used in snippet title
        :title_props => ["http://purl.org/dc/terms/title", "http://ogp.me/ns#title"],
        :nested_props => ["http://purl.org/dc/terms/title", "http://ogp.me/ns#title"],
        :body_props => [
          "http://xmlns.com/foaf/0.1/topic",
          "http://xmlns.com/foaf/0.1/primaryTopic",
          "http://purl.org/dc/terms/subject",
          "http://ogp.me/ns#url",
          "http://rdfs.org/sioc/ns#has_creator",
        ],
        # Priority of this snippet when multiple are matched. If it's missing, it's assumed to be 99
        # When multiple snippets are matched by an object, the one with the highest priority wins.
        :priority => 50,
      }
    })
  end
end

