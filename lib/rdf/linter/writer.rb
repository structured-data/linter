require 'rdf/rdfa/writer'
require 'rdf/linter/rdfa_template'

module RDF::Linter
  ##
  # HTML Writer for Linter.
  #
  # Adds some special-purpose controls to the RDF::RDFa::Writer class
  class Writer < RDF::RDFa::Writer
    def initialize(output = $stdout, options = {}, &block)
      options = {
        :standard_prefixes => true,
        :haml => LINTER_HAML,
      }.merge(options)
      super do
        block.call(self) if block_given?
      end
    end
    
    ##
    # Override render_document to pass `turtle` as a local
    #
    # `turtle` is entity-escaped Turtle serialization of graph
    def render_document(subjects, options = {})
      super(subjects, options.merge(:turtle => escape_entities(graph.dump(:ttl, @options)))) do |subject|
        yield(subject) if block_given?
      end
    end

    # Override render_subject to look for a :rel template if this is a relation.
    # In which case, we'll also pass the typeof the referencing resource
    def render_subject(subject, predicates, options = {})
      options = options.merge(:haml => haml_template[:rel]) if options[:rel] && haml_template[:rel]
      super(subject, predicates, options) do |predicate|
        yield(predicate) if block_given?
      end
    end

    ##
    # Override order_subjects to prefer subjects having an rdf:type
    # @return [Array<Resource>] Ordered list of subjects
    def order_subjects
      subjects = graph.tsort rescue super # TSort can fail
      typed_subjects = subjects.select {|s| graph.first_object(:subject => s, :predicate => RDF.type)}
      typed_subjects + (subjects - typed_subjects)
    end

    ##
    # Generate markup for a rating.
    #
    # Ratings use the [jQuery Raty](http://www.wbotelhos.com/raty/) as the visual representation, normalized to a
    # five-star scale.
    #
    # This plugin is required, as rich-snipets will handle multiple markups for ratings
    #
    # Ratings are expressed differently in RDFa, Microdata and Microformats (different URI prefixes).
    # They may include
    #   * From Schema.org: bestRating, worstRating, ratingValue, ratingCount, reviewCount
    #   * From Microformats hReview: rating, worst, best, value, count, votes, average
    # @example
    #     <img property="v:rating" src="four_star_rating.gif" content="4" />
    #
    #     <span xmlns:v="http://rdf.data-vocabulary.org/#" typeof="v:Review"> 
    #       <span property="v:itemreviewed">Blast 'Em Up</span>—Game Review
    #       <span rel="v:rating"> 
    #          <span typeof="v:Rating">
    #             Rating:
    #             <span property="v:value">7</span> out of 
    #             <span property="v:best">10</span> 
    #          </span>
    #       </span> 
    #     </span>
    #
    # @param [String] property
    # @param [RDF::Resource] object
    # @param [String] property
    # @return [String]
    #   HTML+RDFa markup of review using Raty.
    def rating_helper(property, object)
      STDERR.puts "rating_helper(#{property}, #{object})"
      worst = 1.0
      best = 5.0
      @rating_id ||= "rating-0"
      id = @rating_id.succ
      html = %(<span class='rating-stars' id="#{id}"></span>)
      if object.literal?
        # Value is simiple rating
        rating = object.value.to_f
        html += %(<span property="#{get_curie(property)}" content="#{rating}"/>)
      else
        html += %(<span rel='#{get_curie(property)}' resource='#{object}'/>)
        # It is marked up in a Review class
        graph.query(:subject => object) do |st|
          case st.predicate.to_s
          when /best(?:Rating)/
            best = st.object.value.to_f
          when /worst(?:Rating)/
            worst = st.object.value.to_f
          when /(ratingValue|value|average)/
            rating = st.object.value.to_f
          end
        end
      end

      STDERR.puts "rating_helper(#{property}, #{object}): #{html}"
      html + %(
        <script type="text/javascript">
          $(function () {
            $('##{id}').raty({
              readOnly:   true,
              half:       true,
              start:      #{rating},
              number:     #{best.to_i}
            })
          })
        </script>
      )
    end
  end
end