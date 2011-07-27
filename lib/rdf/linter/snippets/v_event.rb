# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Event" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Event" => "http://data-vocabulary.org/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        # Properties to be used in snippet title
        :title_props => ["#{prefix}summary"],
        # Properties to be used in snippet photo
        :photo_props => ["#{prefix}photo"],
        # Properties to be used in snippet body
        :body_props => [
          "#{prefix}startDate",
          "#{prefix}location",
        ],
        # Post-processing on nested markup
        :body_fmt => lambda {|list, &block|
          startDate = block.call("#{prefix}startDate")
          location = block.call("#{prefix}location")
          [startDate, location].compact.join("- ")
        },
        :description_props => ["#{prefix}description"],
        # Properties to be used when snippet is nested
        :nested_props => [
          "#{prefix}street-address",
          "#{prefix}locality",
          "#{prefix}region",
          "#{prefix}country-name",
          "#{prefix}postal-code",
        ],
        # Post-processing on nested markup
        :nested_fmt => lambda {|list, &block| list.map{|p| block.call(p).rstrip}.join(", ")},
        :property_value => %(
          - if object.node? && res = yield(object)
            != res
          - elsif ["#{prefix}image", "#{prefix}photo"].include?(predicate) 
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
end