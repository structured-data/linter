# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Review" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Review" => "http://data-vocabulary.org/",
    "http://rdf.data-vocabulary.org/#Review-aggregate" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Review-aggregate" => "http://data-vocabulary.org/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :identifier => type,
        # Properties to be used in snippet title
        :title_props => ["#{prefix}itemreviewed", "#{prefix}addr"],
        # Post-processing on nested markup
        :title_fmt => lambda {|list, &block| list.map{|e| block.call(e)}.compact.join("- ")},
        # Properties to be used in snippet photo
        :photo_props => ["#{prefix}image"],
        # Properties to be used in snippet body
        :body_props => [
          "#{prefix}rating",
          "#{prefix}count",
        ],
        # Post-processing on nested markup
        :body_fmt => lambda {|list, &block|
          rating = block.call("#{prefix}rating")
          count = block.call("#{prefix}count")
          rating.to_s + (count ? "#{count} reviews" : "")
        },
        :description_props => ["#{prefix}summary"],
        # Properties to be used when snippet is nested
        :nested_props => [
          "#{prefix}rating",
          "#{prefix}count",
        ],
        :nested_fmt => lambda {|list, &block| list.map{|e| block.call(e)}.join("") + "reviews"},
        :property_value => %(
          - if predicate.to_s.match('#{prefix.gsub('#', '\#')}rating')
            != rating_helper(predicate, object)
          - elsif res = yield(object)
            != res
          - elsif ["#{prefix}image", "#{prefix}photo"].include?(predicate)
            %img{:property => rel, :src => object.to_s, :alt => ""}
          - elsif object.literal?
            %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
          - else
            %link{:property => rel, :href => get_curie(object)}
        ),
        # Priority of this snippet when multiple are matched. If it's missing, it's assumed to be 99
        # When multiple snippets are matched by an object, the one with the highest priority wins.
        :priority => 15,
      }
    })
  end
end