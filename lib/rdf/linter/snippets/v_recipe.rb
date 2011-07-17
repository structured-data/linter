# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    Vocab::V.Recipe => Vocab::V.to_uri.to_s,
    Vocab::VMD.Recipe => RDF::MD.send(Vocab::VMD.Recipe.to_s + "%23:").to_s,
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      type => {
        :subject => %(
          %div{:class => "snippet-content", :about => about, :typeof => typeof}
            %h3.r
              %a.fakelink
                - recipeType = yield("#{prefix}recipeType")
                - name = yield("#{prefix}name")
                = [recipeType, name].compact.join("- ")
            %div.s
              %table.ts
                %tr
                  = yield("#{prefix}photo")
                  %td.primary-content
                    %div.f
                      = yield("#{prefix}review")
                      - if cookTime = yield("#{prefix}cookTime")
                        = "- Total Cook Time:"
                        = cookTime
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
                  - predicates.reject{|p| p.to_s.match('#{prefix.gsub('#', '\#')}(recipeType|name|photo|review|count|cookTime|summary)$')}.each do |predicate|
                    != yield(predicate)
                  
        ),
        :property_value => %(
          - if object.node? && res = yield(object)
            != res
          - elsif predicate.to_s.match('#{prefix.gsub('#', '\#')}(recipeType|name|photo|review|count|cookTime|summary)$')
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