# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    # Match on multiple types
    [
      RDF::URI("http://rdfs.org/sioc/ns#Item"),
      RDF::URI("http://types.ogp.me/ns#article"),
    ] => {
      :identifier => "sioc:Item ogt#article",
      # Properties to be used in snippet title
      :title_props => [
        "http://purl.org/dc/terms/title",
        "http://ogp.me/ns#title",
        "http://ogp.me/ns#site_name",
      ],
      :nested_props => [
          "http://purl.org/dc/terms/title",
          "http://ogp.me/ns#title",
          "http://ogp.me/ns#site_name",
        ],
      :body_props => [
        "http://xmlns.com/foaf/0.1/topic",
        "http://xmlns.com/foaf/0.1/primaryTopic",
        "http://purl.org/dc/terms/subject",
        "http://ogp.me/ns#url",
        "http://rdfs.org/sioc/ns#has_creator",
        "http://ogp.me/ns#date",
      ],
      # Priority of this snippet when multiple are matched. If it's missing, it's assumed to be 99
      # When multiple snippets are matched by an object, the one with the highest priority wins.
      :priority => 15,
    }
  })
end

