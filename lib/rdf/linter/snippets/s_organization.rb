# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    RDF::URI("http://schema.org/Organization") => {
      :identifier => "schema:Organization",
      # Properties to be used in snippet title
      :title_props => ["http://schema.org/name"],
      # Properties to be used in snippet photo
      :photo_props => ["http://schema.org/image"],
      # Properties to be used in snippet body
      :body_props => [
        "http://schema.org/aggregateRating",
        "http://schema.org/reviews",
        "http://schema.org/location",
        "http://schema.org/telephone",
      ],
      # Post-processing on nested markup
      :body_fmt => lambda {|list, &block|
        ratings = block.call("http://schema.org/aggregateRating")
        reviews = block.call("http://schema.org/reviews")
        addr = block.call("http://schema.org/location")
        tel = block.call("http://schema.org/telephone")
        ratings.to_s + reviews.to_s + [addr, tel].compact.map(&:to_s).map(&:rstrip).join(" - ")
      },
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
          %img{:property => rel, :src => object.to_s, :alt => ""}
        - elsif object.literal?
          %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
        - else
          %link{:property => rel, :href => get_curie(object)}
      ),
      # Priority of this snippet when multiple are matched. If it's missing, it's assumed to be 99
      # When multiple snippets are matched by an object, the one with the highest priority wins.
      :priority => 10,
    }
  })
end