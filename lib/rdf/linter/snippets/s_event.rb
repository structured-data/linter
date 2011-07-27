# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    RDF::URI("http://schema.org/Event") => {
      # Properties to be used in snippet title
      :title_props => ["http://schema.org/name"],
      # Properties to be used in snippet photo
      :photo_props => ["http://schema.org/image"],
      # Properties to be used in snippet body
      :body_props => [
        "http://schema.org/startDate",
        "http://schema.org/location",
      ],
      # Post-processing on nested markup
      :body_fmt => lambda {|list, &block|
        startDate = block.call("http://schema.org/startDate")
        location = block.call("http://schema.org/location")
        [startDate, location].compact.join("- ")
      },
      :description_props => ["http://schema.org/description"],
      # Properties to be used when snippet is nested
      :nested_props => [
        "http://schema.org/name",
      ],
      # Post-processing on nested markup
      :nested_fmt => lambda {|list, &block| list.map{|p| block.call(p).to_s.rstrip}.join(", ")},
      :property_value => %(
        - if res = yield(object)
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