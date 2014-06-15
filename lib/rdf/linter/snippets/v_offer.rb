# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Offer" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Offer" => "http://data-vocabulary.org/",
    "http://rdf.data-vocabulary.org/#OfferAggregate" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/OfferAggregate" => "http://data-vocabulary.org/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :identifier => type,
        # Properties to be used in snippet title
        :title_props => ["#{prefix}itemOffered"],
        # Properties to be used in snippet photo
        :photo_props => ["#{prefix}photo"],
        # Properties to be used in snippet body
        :body_props => [
          "#{prefix}offerCount",
          "#{prefix}price",
          "#{prefix}lowPrice",
          "#{prefix}highPrice",
          "#{prefix}currency",
          "#{prefix}description",
        ],
        # Post-processing on nested markup
        :body_fmt => lambda {|list, &block|
          offerCount = block.call("#{prefix}offerCount")
          price = block.call("#{prefix}price")
          lowPrice = block.call("#{prefix}lowPrice")
          highPrice = block.call("#{prefix}highPrice")
          price ||= [lowPrice, highPrice].compact.map(&:to_s).map(&:rstrip).join("-")
          offerCount.to_s + price.to_s + block.call("#{prefix}currency")
        },
        :description_props => ["#{prefix}description"],
        # Properties to be used when snippet is nested
        :nested_props => [
          "#{prefix}price",
          "#{prefix}lowPrice",
          "#{prefix}highPrice",
          "#{prefix}currency",
        ],
        # Post-processing on nested markup
        :nested_fmt => lambda {|list, &block|
          price = block.call("#{prefix}price")
          lowPrice = block.call("#{prefix}lowPrice")
          highPrice = block.call("#{prefix}highPrice")
          price ||= [lowPrice, highPrice].compact.map(&:to_s).map(&:rstrip).join("-")
          currency =  block.call("#{prefix}currency")
          "#{price}#{currency}"
        },
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
        :priority => 20,
      }
    })
  end
end