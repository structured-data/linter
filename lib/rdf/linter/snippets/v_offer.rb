# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Offer" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Offer" => "http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Offer%23:",
    "http://rdf.data-vocabulary.org/#Offer-aggregate" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Offer-aggregate" => "http://www.w3.org/1999/xhtml/microdata#http://data-vocabulary.org/Offer-aggregate%23:",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :rel => %(
          %span{:typeof => typeof}
            - price = yield("#{prefix}price")
            - lowPrice = yield("#{prefix}lowPrice")
            - highPrice = yield("#{prefix}highPrice")
            - price ||= [lowPrice, highPrice].compact.map(&:rstrip).join("-")
            = price
            = yield("#{prefix}currency")
            -#
              Content not used in snippet generation
            %span.other
              - predicates.reject{|p| p.to_s.match('#{prefix.gsub('#', '\#')}(price|lowPrice|highPrice|currency)$')}.each do |predicate|
                != yield(predicate)
        ),
        :subject => %(
          %div{:class => "snippet-content", :about => about, :typeof => typeof}
            %h3.r
              %a.fakelink
              = yield("#{prefix}itemOffered")
            %div.s
              %div.f
                - if offerCount = yield("#{prefix}offerCount")
                  = offerCount
                  available from
                - price = yield("#{prefix}price")
                - lowPrice = yield("#{prefix}lowPrice")
                - highPrice = yield("#{prefix}highPrice")
                - currency = yield("#{prefix}currency")
                - price ||= [lowPrice, highPrice].compact.join("-")
                = price
                = yield("#{prefix}currency")
              - if description = yield("#{prefix}description")
                %br
                = description
              %br
              %span.f
                %cite!= base
            %div.other
              %p="Content not used in snippet generation:"
              %table.properties
                %tbody
                  - predicates.reject{|p| p.to_s.match('#{prefix.gsub('#', '\#')}(itemOffered|price|lowPrice|highPrice|offerCount|currency|description)$')}.each do |predicate|
                    != yield(predicate)
                
        ),
        :property_value => %(
          - if object.node? && res = yield(object)
            != res
          - elsif predicate.to_s.match('#{prefix.gsub('#', '\#')}(itemOffered|price|lowPrice|highPrice|offerCount|currency|description)$')
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