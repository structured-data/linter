# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Geo" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Geo" => "http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Geo%23:",
    "http://rdf.data-vocabulary.org/#Ingredient" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Ingredient" => "http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Ingredient%23:",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :subject => %(
          %span.other{:about => resource, :rel => rel, :typeof => typeof}
            - predicates.each do |predicate|
              != yield(predicate)
        ),
        :property_value => %(
          - unless object.literal?
            %span{:rel => rel, :resource => get_curie(object)}
          - else
            %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
        )
      }
    })
  end
end