# data-vocabulary `Person` snippet:
module RDF::Linter
  {
    "http://rdf.data-vocabulary.org/#Address" => "http://rdf.data-vocabulary.org/#",
    "http://data-vocabulary.org/Address" => "http://data-vocabulary.org/",
    "http://www.w3.org/2006/vcard/ns#Address" => "http://www.w3.org/2006/vcard/ns#",
  }.each do |type, prefix|
    LINTER_HAML.merge!({
      RDF::URI(type) => {
        :identifier => type,
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
        :nested_fmt => lambda {|list, &block| list.map{|p| block.call(p)}.compact.map(&:to_s).map(&:rstrip).join(", ")},
        # Priority of this snippet when multiple are matched. If it's missing, it's assumed to be 99
        # When multiple snippets are matched by an object, the one with the highest priority wins.
        :priority => 30,
      }
    })
  end
end