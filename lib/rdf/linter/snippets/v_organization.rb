# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Organization" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Organization" => "http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Organization%23:",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        # :rel is used only in Linter if :rel is true
        :rel => %(
          %span{:typeof => typeof}
            %a.fakelink
              = yield("#{prefix}name")
            %span.other
              -#
                Content not used in snippet generation
              - predicates.reject{|p| p.to_s.match('#{prefix.gsub('#', '\#')}(name)$')}.each do |predicate|
                != yield(predicate)
        ),
        :subject => %(
          %div{:class => "snippet-content", :about => about, :typeof => typeof}
            %h3.r
              %a.fakelink
                = yield("#{prefix}name")
            %div.s
            %table.ts
              %tr
                = yield("#{prefix}photo")
                %td.primary-content
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
            %td.left-image{:rel => rel}
              %a.fakelink
                %img{:src => object.to_s, :alt => ""}
          - elsif object.node? && res = yield(object)
            != res
          - elsif predicate.to_s.match('#{prefix.gsub('#', '\#')}(photo|address|tel|name)$')
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