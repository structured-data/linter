# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    Vocab::V.send("Review-aggregate") => {
      :subject => %q(
        %div{:class => "snippet-content", :about => about, :typeof => typeof}
          %h3.r
            %a.fakelink
              - name = yield("http://rdf.data-vocabulary.org/#itemreviewed")
              - addr = yield("http://rdf.data-vocabulary.org/#address")
              = [name, addr].compact.join("- ")
          %div.s
            %div.f
              -# Use jQuery rating tool?
              -# %div{:id => "raty"}
              = yield("http://rdf.data-vocabulary.org/#rating")
              = yield("http://rdf.data-vocabulary.org/#count")
              reviews
            - if summary = yield("http://rdf.data-vocabulary.org/#summary")
              %br
              = summary
            %span.f
              %cite!= base
          %div.other
            %p="Content not used in snippet generation:"
            %table.properties
              %tbody
                - predicates.reject{|p| p.to_s.match('http://rdf.data-vocabulary.org/\#(itemreviewed|address|rating|count|summary)$')}.each do |predicate|
                  != yield(predicate)
                  
      ),
      :property_value => %q(
        - if object.node? && res = yield(object)
          != res
        - elsif predicate.to_s.match('http://rdf.data-vocabulary.org/\#(itemreviewed|address|rating|count|summary)$')
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