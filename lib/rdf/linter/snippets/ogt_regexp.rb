# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    %r(http://types.ogp.me/ns\#) => "http://ogp.me/ns#",
    %r(http://opengraphprotocol.org/types/) => "http://opengraphprotocol.org/schema/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      type => {
        :identifier => type.to_s,
        # Properties to be used in snippet title
        :title_props => [
          "#{prefix}site_name",
          "http://purl.org/dc/terms/title"
        ],
        :nested_props => ["http://purl.org/dc/terms/title"],
        :photo_props => ["#{prefix}image"],
        :body_props => [
          "#{prefix}url",
          "#{prefix}date",
        ],
        :description_props => ["http://purl.org/rss/1.0/modules/content/encoded"],
        :property_value => %(
        - if res = yield(object)
          != res
        - elsif predicate == "#{prefix}image"
          %img{:property => rel, :src => object.to_s, :alt => ""}
        - elsif object.literal? && object.datatype == "http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral"
          %div{:property => property, :lang => get_lang(object), :datatype => get_dt_curie(object)}
            != object
        - elsif object.literal?
          %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
        - else
          %span{:property => rel, :resource => get_curie(object)}
        ),
        # Priority of this snippet when multiple are matched. If it's missing, it's assumed to be 99
        # When multiple snippets are matched by an object, the one with the highest priority wins.
        :priority => 80,
      }
    })
  end
end

