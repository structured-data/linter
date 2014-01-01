# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    RDF::URI("http://schema.org/Review") => {
      :identifier => "schema:Review",
      # Properties to be used in snippet title
      :title_props => ["http://schema.org/itemReviewed", "http://schema.org/location"],
      # Post-processing on nested markup
      :title_fmt => lambda {|list, &block| list.map{|e| block.call(e)}.compact.join("- ")},
      # Properties to be used in snippet photo
      :photo_props => ["http://schema.org/image"],
      # Properties to be used in snippet body
      :body_props => [
        "http://schema.org/aggregateRating",
        "http://schema.org/reviewRating",
      ],
      :description_props => ["http://schema.org/reviewBody"],
      # Properties to be used when snippet is nested
      :nested_props => [
        "http://schema.org/aggregateRating",
        "http://schema.org/reviewRating",
      ],
      :nested_fmt => lambda {|list, &block| list.map{|e| block.call(e)}.join("") + "reviews"},
      :property_value => %(
        - if predicate.to_s =~ /Rating/
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
      :priority => 30,
    }
  })
end