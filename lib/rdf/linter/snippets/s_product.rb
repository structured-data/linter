# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    RDF::URI("http://schema.org/Product") => {
      # Properties to be used in snippet title
      :title_props => ["http://schema.org/name"],
      # Properties to be used in snippet photo
      :photo_props => ["http://schema.org/image"],
      # Properties to be used in snippet body
      :body_props => [
        "http://schema.org/aggregateRating",
        "http://schema.org/brand",
        "http://schema.org/model",
        "http://schema.org/offers",
      ],
      :description_props => ["http://schema.org/description"],
      # Properties to be used when snippet is nested
      :nested_props => [
        "http://schema.org/name",
      ],
      :property_value => %(
        - if predicate == "http://schema.org/aggregateRating"
          != rating_helper(predicate, object)
        - elsif res = yield(object)
          != res
        - elsif ["http://schema.org/image", "http://schema.org/photo"].include?(predicate) 
          %span{:rel => rel}
            %img{:src => object.to_s, :alt => ""}
        - elsif object.literal?
          %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
        - else
          %span{:rel => rel, :resource => get_curie(object)}
      ),
    }
  })
end