# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Product" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Product" => "http://data-vocabulary.org/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        # Properties to be used in snippet title
        :title_props => ["#{prefix}name"],
        # Properties to be used in snippet photo
        :photo_props => ["#{prefix}image"],
        # Properties to be used in snippet body
        :body_props => [
          "#{prefix}review",
          "#{prefix}category",
          "#{prefix}offerDetails",
        ],
        :description_props => ["#{prefix}description"],
        # Properties to be used when snippet is nested
        :nested_props => [
          "#{prefix}name",
        ],
        :property_value => %(
          - if predicate.to_s.match('#{prefix.gsub('#', '\#')}rating')
            != rating_helper(predicate, object)
          - elsif object.node? && res = yield(object)
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