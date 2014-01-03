# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    RDF::URI("http://schema.org/MusicRecording") => {
      :identifier => "schema:MusicRecording",
      # Properties to be used in snippet title
      :title_props => ["http://schema.org/name"],
      # Properties to be used in snippet photo
      :photo_props => ["http://schema.org/image"],
      # Properties to be used in snippet body
      :body_props => [
        "http://schema.org/byArtist",
        "http://schema.org/inAlbum",
        "http://schema.org/inPlaylist",
        "http://schema.org/aggregateRating",
        "http://schema.org/review",
        "http://schema.org/reviews",
        "http://schema.org/duration",
        "http://schema.org/playCount",
      ],
      :description_props => ["http://schema.org/description"],
      # Properties to be used when snippet is nested
      :nested_props => [
        "http://schema.org/name",
      ],
      :property_value => %(
        - if predicate == "http://schema.org/aggregateRating"
          != rating_helper(predicate, object)
        - elsif res = yield(object)
          != res
        - elsif ["http://schema.org/image", "http://schema.org/photo"].include?(predicate)
          %img{:property => rel, :src => object.to_s, :alt => ""}
        - elsif predicate == "http://schema.org/playCount"
          %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= " - Played " + escape_entities(get_value(object)) + ' times'
        - elsif object.literal?
          %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
        - else
          %link{:property => rel, :href => get_curie(object)}
      ),
      # Priority of this snippet when multiple are matched. If it's missing, it's assumed to be 99
      # When multiple snippets are matched by an object, the one with the highest priority wins.
      :priority => 1,
    }
  })
end
