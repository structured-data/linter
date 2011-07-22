# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Review" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Review" => "http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Review%23:",
    "http://rdf.data-vocabulary.org/#Review-aggregate" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Review-aggregate" => "http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Review-aggregate%23:",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        # :rel is used only in Linter if :rel is true
        :rel => %(
          %span{:typeof => typeof}
            = yield("#{prefix}rating")
            = yield("#{prefix}count")
            reviews
          %span.other
            -#
              Content not used in snippet generation
            - predicates.reject{|p| p.to_s.match('#{prefix.gsub('#', '\#')}(rating|count)$')}.each do |predicate|
              != yield(predicate)
        ),
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
            - if object.literal?
              %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
            - else
              %span{:rel => rel, :resource => get_curie(object)}
        ),      
      }
    })
  end
end