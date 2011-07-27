# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    RDF::URI("http://schema.org/Person") => {
      # Properties to be used in snippet title
      :title_props => ["http://schema.org/name"],
      # Properties to be used in snippet photo
      :photo_props => ["http://schema.org/image"],
      # Properties to be used in snippet body
      :body_props => [
        "http://schema.org/location",
        "http://schema.org/jobTitle",
        "http://schema.org/affiliation",
      ],
      # Post-processing on nested markup
      :body_fmt => lambda {|list, &block|
        location = block.call("http://schema.org/location")
        title = block.call("http://schema.org/jobTitle")
        affiliation = block.call("http://schema.org/affiliation")
        title = [title, affiliation].compact.map(&:to_s).map(&:rstrip).join(", ")
        [location, title].compact.join("- ")
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