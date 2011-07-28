require 'rdf/rdfa/writer'
require 'rdf/linter/rdfa_template'

module RDF::Linter
  ##
  # HTML Writer for Linter.
  #
  # Adds some special-purpose controls to the RDF::RDFa::Writer class
  class Writer < RDF::RDFa::Writer
    ##
    # Ordering of types so that those found earlier in the list are promoted over everything else.
    TYPE_ORDER = [
      RDF::SIOC.Post,
      RDF::SIOC::Types.Comment,
    ]
    
    def initialize(output = $stdout, options = {}, &block)
      options = {
        :standard_prefixes => true,
        :haml => LINTER_HAML,
        :matched_templates => [],
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
    def render_subject(subject, predicates, options = {}, &block)
      options = options.merge(:haml => haml_template[:rel]) if options[:rel] && haml_template[:rel]
      super(subject, predicates, options) do |predicate|
        if predicate.is_a?(Symbol)
          # Special snippet processing
          # Render associated properties with associated or default formatting
          case predicate
          when :other
            props = predicates.map(&:to_s)
            props -= haml_template[:title_props] || []
            props -= haml_template[:body_props] || []
            props -= haml_template[:description_props] || []
            format = lambda {|list| list.map {|e| yield(e)}.join("")}
          when :other_nested
            props = predicates.map(&:to_s)
            props -= haml_template[:nested_props] || []
            format = lambda {|list| list.map {|e| yield(e)}.join("")}
          else
            # Find appropriate entires from template
            props = haml_template["#{predicate}_props".to_sym]
            add_debug "render_subject(#{subject}, #{predicate}): #{props.inspect}"
            format = haml_template["#{predicate}_fmt".to_sym]
          end
          unless props.nil? || props.empty?
            format ||= lambda {|list| list.map {|e| yield(e)}.join("")}
            format.call(props, &block)
          end
        else
          yield(predicate)
        end
      end
    end
    
    ##
    # Override order_subjects to prefer subjects having an rdf:type
    #
    # Subjects are first sorted in topographical order, and then re-ordered by inclusion in
    # TYPE_ORDER.
    #
    # @return [Array<Resource>] Ordered list of subjects
    def order_subjects
      subjects = super
      
      add_debug "order_subjects: #{subjects.inspect}"

      # Prefer subjects with a type listed in the template, followed by subjects with a type, followed by everything else
      ordered_subjects = []
      templated_subjects = []
      typed_subjects = []
      other_subjects = []
      subjects.each do |s|
        properties = @graph.properties(s)
        types = properties[RDF.type.to_s]
        next unless types
        typed_subjects << s

        # See if it's a typed distinguished in TYPE_ORDER
        ordered_subjects << s unless (TYPE_ORDER & types).empty?
        
        # Look for keys based on any type or all types in sorted order
        all_types = types.map(&:to_s).sort.join("")
        if haml_template.has_key?(all_types) || types.detect {|t| template_match(t)}
          templated_subjects << s
        end
      end
      
      other_subjects = subjects - typed_subjects
      typed_subjects = typed_subjects - templated_subjects
      templated_subjects = templated_subjects - ordered_subjects
      
      add_debug "ordered_subjects: #{ordered_subjects.inspect}\n" + 
                  "templated_subjects: #{templated_subjects.inspect}\n" + 
                  "typed_subjects: #{typed_subjects.inspect}\n" + 
                  "other_subjects: #{other_subjects.inspect}"

      ordered_subjects + templated_subjects + typed_subjects + other_subjects
    end

    ##
    # Keep track of matchted templates
    def template_match(type)
      v = super(type)
      if v.is_a?(Array)
        @options[:matched_templates] << v.first
      end
      v
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
      worst = 1.0
      best = 5.0
      @rating_id ||= "rating-0"
      @rating_id = id = @rating_id.succ
      html = %(<span class='rating-stars' id="#{id}"></span>)
      if object.literal?
        # Value is simiple rating
        rating = object.value.to_f
        html += %(<span property="#{get_curie(property)}" content="#{rating}"/>)
      else
        html += %(<span rel='#{get_curie(property)}' resource='#{object}'>)
        subject_done(object)
        # It is marked up in a Review class
        graph.query(:subject => object) do |st|
          html += %(<span property='#{get_curie(st.predicate)}' content='#{st.object}' />)
          case st.predicate.to_s
          when /best(?:Rating)/
            best = st.object.value.to_f
          when /worst(?:Rating)/
            html += %(<span property='#{get_curie(st.predicate)}' content='#{st.object.value.to_f}' />)
          when /(ratingValue|value|average)/
            rating = st.object.value.to_f
          when /reviewCount/
            html += "#{st.object.value.to_i} reviews"
          end
        end
        html += %(</span>)
      end

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