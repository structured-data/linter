# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    Vocab::V.Address => {
      :subject => %q(
        %span{:about => resource, :rel => rel, :typeof => typeof}
          - street = predicates.delete(RDF::Linter::Vocab::V.send("street-address"))
          - locality = predicates.delete(RDF::Linter::Vocab::V.send("locality"))
          - region = predicates.delete(RDF::Linter::Vocab::V.send("region"))
          - country = predicates.delete(RDF::Linter::Vocab::V.send("country-name"))
          - zip = predicates.delete(RDF::Linter::Vocab::V.send("postal-code"))
          = [street, locality, region, country, zip].compact.map{|p| yield(p).rstrip}.join(", ")
          - predicates.each do |predicate|
            != yield(predicate)
      ),
      :property_value => %q(
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