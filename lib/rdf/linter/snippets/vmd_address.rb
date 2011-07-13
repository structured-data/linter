# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    Vocab::VMD.Address => {
      :subject => %q(
        %span.snippet{:about => resource, :rel => rel, :typeof => typeof}
          - street = predicates.delete('http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Address%23:street-address')
          - locality = predicates.delete('http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Address%23:locality')
          - region = predicates.delete('http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Address%23:region')
          - country = predicates.delete('http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Address%23:country-name')
          - zip = predicates.delete('http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Address%23:postal-code')
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