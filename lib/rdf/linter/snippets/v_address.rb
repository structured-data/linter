# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    Vocab::V.Address => Vocab::V.to_uri.to_s,
    Vocab::VMD.Address => RDF::MD.send(Vocab::VMD.Address.to_s + "%23:").to_s,
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      type => {
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
          - object = objects.first
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