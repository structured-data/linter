# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Recipe" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Recipe" => "http://data-vocabulary.org/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :identifier => type,
        # Properties to be used in snippet title
        :title_props => ["#{prefix}recipeType", "#{prefix}name"],
        # Post-processing on nested markup
        :title_fmt => lambda {|list, &block| list.map{|e| block.call(e)}.compact.join("- ")},
        # Properties to be used in snippet photo
        :photo_props => ["#{prefix}image"],
        # Properties to be used in snippet body
        :body_props => [
          "#{prefix}review",
          "#{prefix}cookTime",
        ],
        # Post-processing on nested markup
        :body_fmt => lambda {|list, &block|
          review = block.call("#{prefix}review")
          cookTime = block.call("#{prefix}cookTime")
          review.to_s + (cookTime ? "- Total cook time: #{cookTime}" : "")
        },
        :description_props => ["#{prefix}summary"],
        # Properties to be used when snippet summary nested
        :nested_props => [
          "#{prefix}name",
        ],
        :property_value => %(
          - if res = yield(object)
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
        :priority => 10,
      }
    })
  end
end