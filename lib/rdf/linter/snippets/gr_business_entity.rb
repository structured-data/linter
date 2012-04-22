# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    RDF::URI("http://purl.org/goodrelations/v1#BusinessEntity") => {
      :identifier => "gr:BusinessEntity",
      # Properties to be used in snippet title
      :title_props => ["http://purl.org/goodrelations/v1#legalName"],
      # Properties to be used in snippet photo
      :photo_props => ["http://xmlns.com/foaf/0.1/depiction"],
      # Properties to be used in snippet body
      :body_props => [
        "http://purl.org/goodrelations/v1#category",
        "http://purl.org/goodrelations/v1#offers",
        "http://purl.org/goodrelations/v1#owns",
        "http://www.w3.org/2006/vcard/ns#adr",
        "http://www.w3.org/2006/vcard/ns#tel",
        "http://purl.org/goodrelations/v1#hasPOS",
      ],
      :description_props => [
        "http://purl.org/goodrelations/v1#description",
        "http://www.w3.org/2000/01/rdf-schema#comment",
      ],
      # Properties to be used when snippet is nested
      :nested_props => [
        "http://purl.org/goodrelations/v1#legalName",
      ],
      :property_value => %(
        - if res = yield(object)
          != res
        - elsif predicate == "http://xmlns.com/foaf/0.1/depiction"
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