# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Address" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Address" => "http://data-vocabulary.org/",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        # Properties to be used in snippet title
        :title_props => [
          "#{prefix}street-address",
          "#{prefix}locality",
          "#{prefix}region",
        ],
        # Properties to be used in snippet photo
        :photo_props => [],
        # Properties to be used in snippet body
        :body_props => [
          "#{prefix}country-name",
          "#{prefix}postal-code",
        ],
        # Properties to be used when snippet is nested
        :nested_props => [
          "#{prefix}street-address",
          "#{prefix}locality",
          "#{prefix}region",
          "#{prefix}country-name",
          "#{prefix}postal-code",
        ],
        # Post-processing on nested markup
        :nested_fmt => lambda {|list, &block| list.map{|p| block.call(p)}.compact.map(&:rstrip).join(", ")},
      }
    })
  end
end