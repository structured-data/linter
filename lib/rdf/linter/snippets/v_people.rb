# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    Vocab::V.Person => {
      :subject => %q(
        %div{:class => "snippet-content", :about => about, :typeof => typeof}
          %h3.r
            %a.fakelink
              = yield("http://rdf.data-vocabulary.org/#name")
          %div.s
            %table.ts
              %tr
                = yield("http://rdf.data-vocabulary.org/#photo")
                %td{:valign => "top"}
                  %div.f
                    - addr = yield("http://rdf.data-vocabulary.org/#address")
                    - title = yield("http://rdf.data-vocabulary.org/#title")
                    - affiliation = yield("http://rdf.data-vocabulary.org/#affiliation")
                    - title = [title, affiliation].compact.map(&:rstrip).join(", ")
                    != [addr, title].compact.join("- ")
                  %br
                  %span.f
                    %cite!= yield("http://rdf.data-vocabulary.org/#url")
          %div.other
            %p="Content not used in snippet generation:"
            %table.properties
              %tbody
                - predicates.reject{|p| p.to_s.match('http://rdf.data-vocabulary.org/\#(address|title|affiliation|name|url)$')}.each do |predicate|
                  != yield(predicate)
                  
      ),
      :property_value => %q(
        - if object.node? && res = yield(object)
          != res
        - elsif predicate.to_s.match('http://rdf.data-vocabulary.org/\#(address|title|affiliation|name|url)$')
          - if predicate == "http://rdf.data-vocabulary.org/#photo"
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