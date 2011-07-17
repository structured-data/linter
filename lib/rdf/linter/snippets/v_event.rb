# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    Vocab::V.Event => Vocab::V.to_uri.to_s,
    Vocab::VMD.Event => RDF::MD.send(Vocab::VMD.Event.to_s + "%23:").to_s,
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      type => {
        :subject => %(
          %div{:class => "snippet-content", :about => about, :typeof => typeof}
            %h3.r
              %a.fakelink
                = yield("#{prefix}summary")
            %div.s
              %table.ts
                %tr
                  = yield("#{prefix}photo")
                  %td.primary-content
                    %div.f
                      - startDate = yield("#{prefix}startDate")
                      - location = yield("#{prefix}location")
                      != [startDate, location].compact.join("- ")
                    - if description = yield("#{prefix}description")
                      %br
                      = description
                      %br
                      %span.f
                        %cite!= base
            %div.other
              -#
                Content not used in snippet generation
              - predicates.reject{|p| p.to_s.match('#{prefix.gsub('#', '\#')}(summary|photo|startDate|location|description)$')}.each do |predicate|
                != yield(predicate)
                  
        ),
        :property_value => %(
          - if object.node? && res = yield(object)
            != res
          - elsif predicate.to_s.match('#{prefix.gsub('#', '\#')}(summary|photo|startDate|location|description)$')
            - if predicate == "#{prefix}photo"
              %td.left-image{:rel => rel}
                %a.fakelink
                  %img{:src => object.to_s, :alt => ""}
            - elsif object.uri?
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