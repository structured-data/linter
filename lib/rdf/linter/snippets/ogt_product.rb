# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://types.ogp.me/ns#product" => "http://ogp.me/ns#",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :identifier => type,
        # Properties to be used in snippet title
        :title_props => ["#{prefix}title"],
        # Properties to be used in snippet photo
        :photo_props => ["#{prefix}image"],
        # Properties to be used in snippet body
        :body_props => [
          "#{prefix}review",
          "#{prefix}site_name",
          "#{prefix}category",
          "#{prefix}offerDetails",
        ],
        :description_props => ["#{prefix}description"],
        # Properties to be used when snippet is nested
        :nested_props => [
          "#{prefix}title",
        ],
        :property_value => %(
          - if predicate.to_s.match('#{prefix.gsub('#', '\#')}rating')
            != rating_helper(predicate, object)
          - elsif res = yield(object)
            != res
          - elsif ["#{prefix}image", "#{prefix}photo"].include?(predicate) 
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
end