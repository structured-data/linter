# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    Vocab::V.Person => Vocab::V.to_uri.to_s,
    Vocab::VMD.Person => RDF::MD.send(Vocab::VMD.Person.to_s + "%23:").to_s,
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
                  %td.primary_content
                    %div.f
                      - addr = yield("#{prefix}address")
                      - title = yield("#{prefix}title")
                      - affiliation = yield("#{prefix}affiliation")
                      - title = [title, affiliation].compact.map(&:rstrip).join(", ")
                      != [addr, title].compact.join("- ")
                    %br
                    %span.f
                      %cite!= base
            %div.other
              %p="Content not used in snippet generation:"
              %table.properties
                %tbody
                  - predicates.reject{|p| p.to_s.match('#{prefix.gsub('#', '\#')}(address|title|affiliation|name|photo)$')}.each do |predicate|
                    != yield(predicate)
                  
        ),
        :property_value => %(
          - if predicate == "#{prefix}photo"
            %td.left-image{:rel => rel}
              %a.fakelink
                %img{:src => object.to_s, :alt => ""}
          - elsif object.node? && res = yield(object)
            != res
          - elsif predicate.to_s.match('#{prefix.gsub('#', '\#')}(address|title|affiliation|name|photo)$')
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
            - if object.literal?
              %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
            - else
              %span{:rel => rel, :resource => get_curie(object)}
        ),      
      }
    })
  end
end