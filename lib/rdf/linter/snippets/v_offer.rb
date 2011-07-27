# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Offer" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Offer" => "http://data-vocabulary.org/",
    "http://rdf.data-vocabulary.org/#Offer-aggregate" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Offer-aggregate" => "http://data-vocabulary.org/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
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
          price ||= [lowPrice, highPrice].compact.map(&:rstrip).join("-")
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
          price ||= [lowPrice, highPrice].compact.map(&:rstrip).join("-")
          currency =  block.call("#{prefix}currency")
          "#{price}#{currency}"
        },
        :property_value => %(
          - if predicate.to_s.match('#{prefix.gsub('#', '\#')}rating')
            != rating_helper(predicate, object)
          - elsif object.node? && res = yield(object)
            != res
          - elsif ["#{prefix}image", "#{prefix}photo"].include?(predicate) 
            %span{:rel => rel}
              %img{:src => object.to_s, :alt => ""}
          - elsif object.literal?
            %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
          - else
            %span{:rel => rel, :resource => get_curie(object)}
        ),      
      }
    })
  end
end