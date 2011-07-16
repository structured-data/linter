# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    Vocab::V.send("Review-aggregate") => Vocab::V.to_uri.to_s,
    Vocab::VMD.send("Review-aggregate") => RDF::MD.send(Vocab::VMD.send("Review-aggregate").to_s + "%23:").to_s,
    Vocab::V.Review => Vocab::V.to_uri.to_s,
    Vocab::VMD.Review => RDF::MD.send(Vocab::VMD.Review.to_s + "%23:").to_s,
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      type => {
        :subject => %(
          %div{:class => "snippet-content", :about => about, :typeof => typeof}
            %h3.r
              %a.fakelink
                - name = yield("#{prefix}itemreviewed")
                - addr = yield("#{prefix}address")
                = [name, addr].compact.join("- ")
            %div.s
              %div.f
                = yield("#{prefix}rating")
                = yield("#{prefix}count")
                reviews
              - if summary = yield("#{prefix}summary")
                %br
                = summary
              %br
              %span.f
                %cite!= base
            %div.other
              %p="Content not used in snippet generation:"
              %table.properties
                %tbody
                  - predicates.reject{|p| p.to_s.match('#{prefix.gsub('#', '\#')}(itemreviewed|address|rating|count|summary)$')}.each do |predicate|
                    != yield(predicate)
                  
        ),
        :property_value => %(
          - if predicate.to_s.match('#{prefix.gsub('#', '\#')}rating')
            != rating_helper(predicate, object)
          - elsif object.node? && res = yield(object)
            != res
          - elsif predicate.to_s.match('#{prefix.gsub('#', '\#')}(itemreviewed|address|rating|count|summary)$')
            - if object.uri?
              %span{:rel => rel}= object.to_s
            - elsif object.node?
              %span{:resource => get_curie(object), :rel => rel}= get_curie(object)
            - else
              %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
          - else
            %tr.property
              %td.label
                = get_predicate_name(predicate)
              - if object.uri?
                %td
                  %a{:href => object.to_s, :rel => rel}= object.to_s
              - elsif object.node?
                %td{:resource => get_curie(object), :rel => rel}= get_curie(object)
              - else
                %td{:property => property}= escape_entities(get_value(object))
        ),      
      }
    })
  end
end