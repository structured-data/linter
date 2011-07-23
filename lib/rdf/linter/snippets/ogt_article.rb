# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    [
      "http://types.ogp.me/ns#article",
      "http://rdfs.org/sioc/ns#Item",
      "http://xmlns.com/foaf/0.1/Document"
    ].sort.join("") => {
      # Properties to be used in snippet title
      :title_props => [
        "http://ogp.me/ns#site_name",
        "http://purl.org/dc/terms/title"
      ],
      :nested_props => ["http://purl.org/dc/terms/title"],
      :photo_props => ["http://ogp.me/ns#image"],
      :body_props => [
        "http://ogp.me/ns#url",
        "http://ogp.me/ns#date",
      ],
      :description_props => ["http://purl.org/rss/1.0/modules/content/encoded", "http://ogp.me/ns#url"],
      :property_value => %q(
      - if res = yield(object)
        != res
      - elsif ["http://ogp.me/ns#image"].include?(predicate) 
        %span{:rel => rel}
          %img{:src => object.to_s, :alt => ""}
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

