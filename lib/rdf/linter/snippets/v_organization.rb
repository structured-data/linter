# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    Vocab::V.Organization => Vocab::V.to_uri.to_s,
    Vocab::VMD.Organization => RDF::MD.send(Vocab::VMD.Organization.to_s + "%23:").to_s,
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
                = yield("#{prefix}photo")
                %td{:valign => "top"}
                  %div.f
                    - addr = yield("#{prefix}address")
                    - tel = yield("#{prefix}tel")
                    != title = [addr, tel].compact.map(&:rstrip).join(" - ")
                    %br
                    %span.f
                      %cite!= base
            %div.other
              %p="Content not used in snippet generation:"
              %table.properties
                %tbody
                  - predicates.reject{|p| p.to_s.match('#{prefix.gsub('#', '\#')}(photo|address|tel|name)$')}.each do |predicate|
                    != yield(predicate)
                  
        ),
        :property_value => %(
          - if predicate == "#{prefix}photo"
            %td{:valign => "top"}
              %div.left-image{:rel => rel}
                %a.fakelink
                  %img{:src => object.to_s, :alt => "", :align => "middle", :border => "1", :height => "60", :width => "80"}
          - elsif object.node? && res = yield(object)
            != res
          - elsif predicate.to_s.match('#{prefix.gsub('#', '\#')}(photo|address|tel|name)$')
            - if predicate == "#{prefix}photo"
              %td{:valign => "top"}
                %div.left-image{:rel => rel}
                  %a.fakelink
                    %img{:src => object.to_s, :alt => "", :align => "middle", :border => "1", :height => "60", :width => "80"}
            - elsif object.uri?
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