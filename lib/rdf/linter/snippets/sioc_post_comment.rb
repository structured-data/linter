# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    # Match on multiple types
    [
      "http://rdfs.org/sioc/ns#Post",
      "http://rdfs.org/sioc/types#Comment"
    ].sort.join("") => {
      # Properties to be used in snippet title
      :title_props => ["http://purl.org/dc/terms/title"],
      :nested_props => ["http://purl.org/dc/terms/title"],
      :body_props => [
        "http://rdfs.org/sioc/ns#has_creator",
        "http://rdfs.org/sioc/ns#reply_of",
        "http://purl.org/dc/terms/date"
      ],
      :description_props => ["http://purl.org/rss/1.0/modules/content/encoded"],
      :property_value => %q(
      - if res = yield(object)
        != res
      - elsif object.literal? && object.datatype == "http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral"
        %div{:property => property, :lang => get_lang(object), :datatype => get_dt_curie(object)}
          != object
      - elsif object.literal?
        %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
      - else
        %span{:rel => rel, :resource => get_curie(object)}
      ),
    }
  })
end

