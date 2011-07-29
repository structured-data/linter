# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://xmlns.com/foaf/0.1/Document" => "http://xmlns.com/foaf/0.1/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        # Properties to be used in snippet title
        :title_props => ["http://purl.org/dc/terms/title", "http://ogp.me/ns#title"],
        :nested_props => ["http://purl.org/dc/terms/title", "http://ogp.me/ns#title"],
        :body_props => [
          "http://xmlns.com/foaf/0.1/topic",
          "http://xmlns.com/foaf/0.1/primaryTopic",
          "http://purl.org/dc/terms/subject",
        ],
      }
    })
  end
end

