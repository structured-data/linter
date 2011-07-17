# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    Vocab::V.Geo => Vocab::V.to_uri.to_s,
    Vocab::VMD.Geo => RDF::MD.send(Vocab::VMD.Geo.to_s + "%23:").to_s,
    Vocab::V.Ingredient => Vocab::V.to_uri.to_s,
    Vocab::VMD.Ingredient => RDF::MD.send(Vocab::VMD.Ingredient.to_s + "%23:").to_s,
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      type => {
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