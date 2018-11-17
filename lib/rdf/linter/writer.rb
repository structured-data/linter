require 'rdf/rdfa/writer'
require 'rdf/linter/rdfa_template'

module RDF::Linter
  ##
  # HTML Writer for Linter.
  #
  # Adds some special-purpose controls to the RDF::RDFa::Writer class
  class Writer < RDF::RDFa::Writer
    format RDF::RDFa::Format
    def initialize(output = $stdout, options = {}, &block)
      options = {
        standard_prefixes: true,
        haml: LINTER_HAML,
        matched_templates: [],
        prefixes: {},
        encoding: "utf-8"
      }.merge(options)
      options[:logger] = options.fetch(:debug, false)
      options[:prefixes].delete(:dcterms) if options[:prefixes].has_key?(:dc)
      super do
        block.call(self) if block_given?
      end
    end

    # Override render_subject to look for a :rel template if this is a relation.
    # In which case, we'll also pass the typeof the referencing resource
    def render_subject(subject, predicates, options = {}, &block)
      options = options.merge(haml: @prev_templ[:rel]) if options[:rel] && @prev_templ[:rel]
      @prev_templ = haml_template
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
            log_debug "render_subject(#{subject}, #{predicate}): #{props.inspect}"
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
    # Subjects are first sorted in topographical order, by highest (lowest numerical) snippet priority.
    #
    # @return [Array<Resource>] Ordered list of subjects
    def order_subjects
      subjects = super
      other_subjects = []
      templates = {}

      log_debug "order_subjects: #{subjects.inspect}"

      # Order subjects by finding those with templates, and then by the template priority order and name

      # Get template priorities for each subject
      subjects.each do |s|
        if (t = find_template(s)) && !t[:skip]
          t[:priority] ||= 99
          templates[s] = t
        else
          other_subjects << s
        end
      end

      # Order subjects by priority or identifier
      ordered_subjects = templates.keys.sort do |s1, s2|
        if templates[s1][:priority] == templates[s2][:priority]
          templates[s1][:identifier] <=> templates[s2][:identifier]
        else
          templates[s1][:priority] <=> templates[s2][:priority]
        end
      end

      log_debug "ordered_subjects: #{ordered_subjects.inspect}\n" + 
                "other_subjects: #{other_subjects.inspect}"

      ordered_subjects + other_subjects
    end

    ##
    # Find a template appropriate for the subject. 
    # Use type information of subject to select among multiple templates
    #
    # In this implementation, find all templates matching on permutations of
    # types of this subjects and choose the one with the lowest :priority
    #
    # Keep track of matched templates
    #
    # @param [RDF::URI] subject
    # @return [Hash] # return matched matched template
    def find_template(subject)
      properties = @graph.properties(subject)
      types = (properties[RDF.type.to_s] || [])
      
      matched_templates = []
      
      (1..types.length).each do |len|
        types.combination(len) do |set|
          templ = @options[:haml] && @options[:haml][set]
          templ ||= haml_template[set]
          if len == 1
            templ ||= @options[:haml] && @options[:haml][set.first]
            templ ||= haml_template[set.first]
          end

          #log_debug "find_template: look for #{set.inspect}"

          # Look for regular expression match
          templ ||= if len == 1
            key = haml_template.keys.detect {|k| k.is_a?(Regexp) && set.first.to_s.match(k)}
            haml_template[key]
          end

          next unless templ
        
          matched_templates[len] ||= []
          matched_templates[len] << templ
        end
      end

      if matched_templates.empty?
        log_debug "find_template: no template found for any #{types.inspect}"
        return nil
      end
      
      list = matched_templates.last
      
      # Order the list of templates by priority
      list = list.sort_by {|templ| templ[:priority] || 99}
      
      # Choose the lowest priority template found
      templ = list.first

      log_debug "find_template: found #{templ[:identifier] || templ.inspect}"

      @options[:matched_templates] << templ[:identifier]
      
      templ
    end
    
    ##
    # Override #get_value to perform lexical matching over selected values, infer datatype
    # and perform datatype-specific formatting
    def get_value(literal)
      if literal.typed?
        literal.humanize
      else
        # Hack to fix incorrect dattime
        case literal.to_s
        when RDF::Literal::Duration::GRAMMAR
          get_value(RDF::Literal::Duration.new(literal))
        when RDF::Literal::Date::GRAMMAR
          get_value(RDF::Literal::Date.new(literal))
        when RDF::Literal::Time::GRAMMAR
          get_value(RDF::Literal::Time.new(literal))
        when RDF::Literal::DateTime::GRAMMAR
          get_value(RDF::Literal::DateTime.new(literal))
        when %r(\A-?\d{4}-\d{2}-\d{2}T\d{2}:\d{2}(:\d{2})?(\.\d+)?(([\+\-]\d{2}:\d{2})|UTC|Z)?\Z)
          # Hack to fix incorrect DateTimes in examples:
          get_value(RDF::Literal::DateTime.new(literal))
        else
          literal.humanize
        end
      end
    end

    ##
    # Generate markup for a rating.
    #
    # Ratings use Unicode star as the visual representation, normalized to a five-star scale.
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
      worst = 0
      best = 5
      rating = 0.0
      html = %(<span class='rating-stars'>)
      postscript = ""

      if object.literal?
        # Value is simiple rating
        rating = object.value.to_f
      else
        subject_done(object)
        # It is marked up in a Review class
        graph.query(subject: object) do |st|
          html += %(<span property='#{get_curie(st.predicate)}' content='#{st.object}' />)
          case st.predicate.to_s
          when /best(?:Rating)/
            best = st.object.value.to_i
          when /worst(?:Rating)/
            worst = st.object.value.to_i
          when /(ratingValue|value|average)/
            rating = st.object.value.to_f
          when /reviewCount/
            postscript = "#{st.object.value.to_i} reviews"
          end
        end
      end

      # FIXME: Normalize rating as 0..5
      %(<span class='star-rating'>
        <i #{'class="star"' if rating > 0}>\u2605</i>
        <i #{'class="star"' if rating > 1}>\u2605</i>
        <i #{'class="star"' if rating > 2}>\u2605</i>
        <i #{'class="star"' if rating > 3}>\u2605</i>
        <i #{'class="star"' if rating > 4}>\u2605</i>
      </span>)
    end
  end
end