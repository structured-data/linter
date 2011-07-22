# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://xmlns.com/foaf/0.1/Document" => "http://xmlns.com/foaf/0.1/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        # Properties to be used in snippet title
        :title_props => ["http://purl.org/dc/terms/title"],
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

