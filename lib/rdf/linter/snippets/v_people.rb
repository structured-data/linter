# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    Vocab::V.Person => {
      :subject => %q(
        %div{:id => "snippet-content", :about => get_curie(subject), :typeof => typeof}
          %h3.r
            %a.fakelink
              = yield("http://rdf.data-vocabulary.org/#name")
          %div.s
            %table.ts
              %tr
                = yield("http://rdf.data-vocabulary.org/#Photo")
                %td{:valign => "top"}
                  %div.f
                    - addr = yield("http://rdf.data-vocabulary.org/#address")
                    - title = yield("http://rdf.data-vocabulary.org/#title")
                    - affiliation = yield("http://rdf.data-vocabulary.org/#affiliation")
                    - title = [title, affiliation].compact.map(&:rstrip).join(", ")
                    != [addr, title].compact.join("- ")
                  %br
                  %span.f
                    %cite
                      = subject.to_s
                  
      ),
      :property_value => %q(
        - object = objects.first
        - if object.node? && res = yield(object)
          != res
        - elsif property == "http://rdf.data-vocabulary.org/#photo"
          %td{:valign => "top"}
            %div.left-image{:rel => get_curie(property)}
              %a.fakelink
                %img{:src => object.to_s, :alt => "", :align => "middle", :border => "1", :height => "60", :width => "80"}
        - elsif object.uri?
          %span{:rel => get_curie(predicate)}= object.to_s
        - elsif object.node?
          %span{:resource => get_curie(object), :rel => get_curie(predicate)}= get_curie(object)
        - else
          %span{:property => get_curie(predicate), :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
      ),      
    }
  })
end