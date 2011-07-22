# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Address" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Address" => "http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Address%23:",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :subject => %(
          %span{:about => resource, :rel => rel, :typeof => typeof}
            - street = predicates.delete(RDF::URI('#{prefix}street-address'))
            - locality = predicates.delete(RDF::URI('#{prefix}locality'))
            - region = predicates.delete(RDF::URI('#{prefix}region'))
            - country = predicates.delete(RDF::URI('#{prefix}country-name'))
            - zip = predicates.delete(RDF::URI('#{prefix}postal-code'))
            = [street, locality, region, country, zip].compact.map{|p| yield(p).rstrip}.join(", ")
            - predicates.each do |predicate|
              != yield(predicate)
        ),
        :property_value => %(
          - if object.node? && res = yield(object)
            != res
          - elsif object.uri?
            %span{:rel => rel}= object.to_s
          - elsif object.node?
            %span{:resource => get_curie(object), :rel => rel}= get_curie(object)
          - else
            %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
        )
      }
    })
  end
end