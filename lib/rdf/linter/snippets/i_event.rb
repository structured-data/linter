# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    RDF::URI("http://www.w3.org/2002/12/cal/ical#Vevent") => {
      :identifier => "ical:Event",
      # Properties to be used in snippet title
      :title_props => ["http://www.w3.org/2002/12/cal/ical#description"],
      # Properties to be used in snippet body
      :body_props => [
        "http://www.w3.org/2002/12/cal/ical#dtstart",
        "http://www.w3.org/2002/12/cal/ical#duration",
        "http://www.w3.org/2002/12/cal/ical#location",
      ],
      :description_props => ["http://schema.org/summary"],
      # Properties to be used when snippet is nested
      :nested_props => [
        "http://www.w3.org/2002/12/cal/ical#description", "http://www.w3.org/2002/12/cal/ical#location"
      ],
      # Post-processing on nested markup
      :nested_fmt => lambda {|list, &block| list.map{|p| block.call(p)}.compact.map(&:to_s).map(&:rstrip).join(", ")},
      :property_value => %(
        - if res = yield(object)
          != res
        - elsif object.literal?
          %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
        - else
          %span{:property => rel, :resource => get_curie(object)}
      ),      
      # Priority of this snippet when multiple are matched. If it's missing, it's assumed to be 99
      # When multiple snippets are matched by an object, the one with the highest priority wins.
      :priority => 10,
    }
  })
end