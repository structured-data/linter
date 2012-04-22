# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdfs.org/sioc/ns#UserAccount" => "http://rdfs.org/sioc/ns#",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :identifier => "sioc:UserAccount",
        # Properties to be used in snippet title
        :title_props => ["http://xmlns.com/foaf/0.1/name"],
        :photo_props => [
          "http://rdfs.org/sioc/ns#avatar",
          "http://rdfs.org/sioc/ns#thumbnail",
          "http://rdfs.org/sioc/ns#depiction",
          "http://rdfs.org/sioc/ns#img",
        ],
        :nested_props => ["http://xmlns.com/foaf/0.1/name"],
        :body_props => [
          "http://rdfs.org/sioc/ns#nick",
          "http://rdfs.org/sioc/ns#homepage",
          "http://rdfs.org/sioc/ns#accountName",
          "http://rdfs.org/sioc/ns#account_of",
          "http://rdfs.org/sioc/ns#creator_of",
          "http://rdfs.org/sioc/ns#follows",
          "http://rdfs.org/sioc/ns#member_of",
          "http://rdfs.org/sioc/ns#owner_of",
          "http://rdfs.org/sioc/ns#modifier_of",
        ],
        :property_value => %(
        - if res = yield(object)
          != res
        - elsif ["http://rdfs.org/sioc/ns#avatar", "http://rdfs.org/sioc/ns#thumbnail", "http://rdfs.org/sioc/ns#depiction", "http://rdfs.org/sioc/ns#img"].include?(predicate) 
          %img{:property => rel, :src => object.to_s, :alt => ""}
        - elsif object.literal? && object.datatype == "http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral"
          %div{:property => property, :lang => get_lang(object), :datatype => get_dt_curie(object)}
            != object
        - elsif object.literal?
          %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
        - else
          %link{:property => rel, :href => get_curie(object)}
        ),
        :priority => 20,
      }
    })
  end
end

