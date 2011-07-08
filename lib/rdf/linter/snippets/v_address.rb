# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    Vocab::V.Address => {
      :subject => %q(
        %span{:about => get_curie(subject), :typeof => typeof}
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
          %span{:rel => get_curie(predicate)}= object.to_s
        - elsif object.node?
          %span{:resource => get_curie(object), :rel => get_curie(predicate)}= get_curie(object)
        - else
          %span{:property => get_curie(predicate), :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
      )
    }
  })
end