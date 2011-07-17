# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    Vocab::V.Product => Vocab::V.to_uri.to_s,
    Vocab::VMD.Product => RDF::MD.send(Vocab::VMD.Product.to_s + "%23:").to_s,
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      type => {
        :subject => %(
          %div{:class => "snippet-content", :about => about, :typeof => typeof}
            %h3.r
              %a.fakelink
                = yield("#{prefix}name")
            %div.s
              %table.ts
                %tr
                  = yield("#{prefix}image")
                  %td.primary-content
                    %div.f
                      = yield("#{prefix}review")
                      - if category = yield("#{prefix}category")
                        = category
                      - if offerDetails = yield("#{prefix}offerDetails")
                        = offerDetails
                    - if description = yield("#{prefix}description")
                      %br
                      = description
                    %br
                    %span.f
                      %cite!= base
            %div.other
              %p="Content not used in snippet generation:"
              %table.properties
                %tbody
                  - predicates.reject{|p| p.to_s.match('#{prefix.gsub('#', '\#')}(name|image|review|category|offerDetails|description)$')}.each do |predicate|
                    != yield(predicate)
                  
        ),
        :property_value => %(
          - if predicate == "#{prefix}image"
            %td.left-image{:rel => rel}
              %a.fakelink
                %img{:src => object.to_s, :alt => ""}
          - elsif predicate.to_s.match('#{prefix.gsub('#', '\#')}rating')
            != rating_helper(predicate, object)
          - elsif object.node? && res = yield(object)
            != res
          - elsif predicate.to_s.match('#{prefix.gsub('#', '\#')}(name|image|review|category|offerDetails|description)$')
            - if object.uri?
              %span{:rel => rel}= object.to_s
            - elsif object.node?
              %span{:resource => get_curie(object), :rel => rel}= get_curie(object)
            - else
              %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
          - else
            - if object.literal?
              %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
            - else
              %span{:rel => rel, :resource => get_curie(object)}
       ),      
      }
    })
  end
end