# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://types.ogp.me/ns#article" => "http://ogp.me/ns#",
    "http://opengraphprotocol.org/types/article" => "http://opengraphprotocol.org/schema/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
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
        :description_props => ["http://purl.org/rss/1.0/modules/content/encoded", "#{prefix}url"],
        :property_value => %q(
        - if res = yield(object)
          != res
        - elsif false && predicate == "#{prefix}image" # FIXME
          %span{:rel => rel}
            %img{:src => object.to_s, :alt => ""}
        - elsif object.literal? && object.datatype == "http://www.w3.org/1999/02/22-rdf-syntax-ns#XMLLiteral"
          %div{:property => property, :lang => get_lang(object), :datatype => get_dt_curie(object)}
            != object
        - elsif object.literal?
          %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
        - else
          %span{:rel => rel, :resource => get_curie(object)}
        ),
      }
    })
  end
end

