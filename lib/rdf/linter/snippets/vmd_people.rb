# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    Vocab::VMD.Person => {
      :subject => %q(
        %td.snippet{:id => "snippet-content", :about => about, :typeof => typeof}
          %h3.r
            %a.fakelink
              = yield("http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Person%23:name")
          %div.s
            %table.ts
              %tr
                = yield("http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Person%23:photo")
                %td{:valign => "top"}
                  %div.f
                    - addr = yield("http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Person%23:address")
                    - title = yield("http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Person%23:title")
                    - affiliation = yield("http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Person%23:affiliation")
                    - title = [title, affiliation].compact.map(&:rstrip).join(", ")
                    != [addr, title].compact.join("- ")
                  %br
                  %span.f
                    %cite!= yield("http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Person%23:url")
          %div.other
            %p="Content not used in snippet generation:"
            %table.properties
              %tbody
                - predicates.reject{|p| p.to_s.match('http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Person%23:(address|title|affiliation|name|url)$')}.each do |predicate|
                  != yield(predicate)
                  
      ),
      :property_value => %q(
        - if object.node? && res = yield(object)
          != res
        - elsif predicate.to_s.match('http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Person%23:(address|title|affiliation|name|url)$')
          - if predicate == "http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Person%23:photo"
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