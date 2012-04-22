# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    RDF::URI("http://schema.org/Event") => {
      :identifier => "schema:Event",
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
        "http://schema.org/name", "http://schema.org/location"
      ],
      # Post-processing on nested markup
      :nested_fmt => lambda {|list, &block| list.map{|p| block.call(p)}.compact.map(&:to_s).map(&:rstrip).join(", ")},
      :property_value => %(
        - if res = yield(object)
          != res
        - elsif ["http://schema.org/image", "http://schema.org/photo"].include?(predicate) 
          %img{:property => rel, :src => object.to_s, :alt => ""}
        - elsif object.literal?
          %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
        - else
          %span{:property => rel, :resource => get_curie(object)}
      ),      
      # Priority of this snippet when multiple are matched. If it's missing, it's assumed to be 99
      # When multiple snippets are matched by an object, the one with the highest priority wins.
      :priority => 10,
    }
  })
end