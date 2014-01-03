require 'rdf/linter/writer'
require 'rdf/linter/vocab_defs'
require 'rdf/xsd'
require 'nokogiri'

module RDF::Linter
  module Parser

    # Parse the an input file and re-serialize based on params and/or content-type/accept headers
    def parse(reader_opts)
      $logger ||= begin
        logger = Logger.new(STDOUT)  # In case we're not invoked from rack
        logger.level = ::RDF::Linter.debug? ? Logger::DEBUG : Logger::INFO
        logger
      end
      graph = RDF::Graph.new
      format = reader_opts[:format]
      reader_opts[:prefixes] ||= {}
      reader_opts[:rdf_terms] = true unless reader_opts.has_key?(:rdf_terms)

      reader_class = RDF::Reader.for(format) || RDF::All::Reader
      reader = case
      when reader_opts[:tempfile]
        reader_class.new(reader_opts[:tempfile], reader_opts) {|r| graph << r}
      when reader_opts[:content]
        reader_class.new(reader_opts[:content], reader_opts) {|r| graph << r}
      when reader_opts[:base_uri]
        reader_class.open(reader_opts[:base_uri], reader_opts) {|r| graph << r}
      else
        return ["text/html", 200, ""]
      end

      @parsed_statements = case reader
      when RDF::All::Reader
        reader.statement_count
      else
        {reader.class => graph.size }
      end

      # Special case for Facebook OGP. Facebook (apparently) doesn't believe in rdf:type,
      # so we look for statements with predicate og:type with a literal object and create
      # an rdf:type in a similar namespace
      graph.query(:predicate => RDF::URI("http://ogp.me/ns#type")) do |statement|
        graph << RDF::Statement.new(statement.subject, RDF.type, RDF::URI("http://types.ogp.me/ns##{statement.object}"))
      end
      
      # Similar, but using old namespace
      graph.query(:predicate => RDF::URI("http://opengraphprotocol.org/schema/type")) do |statement|
        graph << RDF::Statement.new(statement.subject, RDF.type, RDF::URI("http://opengraphprotocol.org/types/#{statement.object}"))
      end

      # Expand types using vocabulary entailment
      graph.query(:predicate => RDF.type) do |statement|
        s = statement.dup
        entailed_types(statement.object).each do |t|
          s.object = t
          graph << s
        end
      end

      # Perform some actual linting on the graph
      @lint_messages = lint(graph)

      writer_opts = reader_opts.dup
      writer_opts[:base_uri] ||= reader.base_uri.to_s unless reader.base_uri.to_s.empty?
      writer_opts[:prefixes][:ogt] = "http://types.ogp.me/ns#"
      writer_opts[:debug] ||= [] if $logger.level <= Logger::DEBUG

      # Move elements with class `snippet` to the front of the root element
      html = RDF::Linter::Writer.buffer(writer_opts) {|w| w << graph}
      writer_opts.fetch(:debug, []).each {|m| $logger.debug m}
      ["text/html", 200, html]
    rescue RDF::ReaderError => e
      @error = "RDF::ReaderError: #{e.message}"
      $logger.error @error
      $logger.debug e.backtrace.join("\n")
      ["text/html", 400, @error]
    rescue IOError => e
      @error = "Failed to open #{reader_opts[:base_uri]}: #{e.message}"
      $logger.error @error  # to log
      $logger.debug e.backtrace.join("\n")
      ["text/html", 502, @error]
    rescue
      raise unless self.respond_to?(:settings) && settings.environment == :production
      @error = "#{$!.class}: #{$!.message}"
      $logger.error @error  # to log
      $logger.debug $!.backtrace.join("\n")
      ["text/html", 400, @error]
    end
    module_function :parse

    # Return entailed super-classes of a given type
    # @param [RDF::URI] type
    # @return [Array<RDF::URI>]
    def entailed_types(type)
      VOCAB_DEFS["Classes"].fetch(type.to_s, {}).fetch("superClass", []).map {|v| RDF::URI(v)}
    end
    module_function :entailed_types

    # Use vocabulary definitions to lint contents of the graph for known vocabularies
    def lint(graph)
      messages = {}

      # Check for defined classes in known vocabularies
      graph.query(:predicate => RDF.type) do |st|
        cls = st.object.to_s
        curie = get_curie(cls)
        unless VOCAB_DEFS["Classes"][cls]
          next unless curie && %w(rdf: rdfs:).none?{|p| curie.start_with?(p)}
          (messages[:class] ||= {})[curie] = ["No class definition found"]
        end
      end

      # Check for defined predicates in known vocabularies and domain/range
      graph.each_statement do |stmt|
        prop = stmt.predicate.to_s
        curie = get_curie(prop)
        unless (defn = VOCAB_DEFS["Properties"][prop])
          ((messages[:property] ||= {})[curie] ||= []) << "No property definition found" if curie && %w(rdf: rdfs:).none?{|p| curie.start_with?(p)}
          next
        end

        # Make sure that if domains are defined, the subject has an appropriate type
        domains = Array(defn["domainIncludes"] || defn["domain"]) - [RDF::OWL.Thing.to_s]
        if domains.length >= 1
          types = graph.query(:subject => stmt.subject, :predicate => RDF.type).map(&:object)
          unless domains.any? {|d| types.include?(d)}
            ((messages[:property] ||= {})[curie] ||= []) <<
              "Subject must have some type defined as domain (#{domains.map {|d| get_curie(d) || d}.join(',')})"
          end
        end

        # Make sure that if ranges are defined, the object has an appropriate type
        ranges = Array(defn["rangeIncludes"] || defn["range"]) - [RDF::OWL.Thing.to_s]
        if ranges.length >= 1
          any_okay = if stmt.object.literal?
            ranges.any? do |range|
              case RDF::URI(range)
              when RDF::RDFS.Literal then true
              when RDF::SCHEMA.Text then stmt.object.plain? || stmt.object.datatype == RDF::SCHEMA.Text
              when RDF::SCHEMA.Boolean
                stmt.object.datatype == RDF::SCHEMA.Boolean ||
                stmt.object.datatype == RDF::XSD.boolean ||
                stmt.object.simple? && RDF::Literal::Boolean.new(stmt.object.value).valid?
              when RDF::SCHEMA.Date
                stmt.object.datatype == RDF::SCHEMA.Date ||
                stmt.object.is_a?(RDF::Literal::Date) ||
                stmt.object.simple? && RDF::Literal::Date.new(stmt.object.value).valid?
              when RDF::SCHEMA.DateTime
                stmt.object.datatype == RDF::SCHEMA.DateTime ||
                stmt.object.is_a?(RDF::Literal::DateTime) ||
                stmt.object.simple? && RDF::Literal::DateTime.new(stmt.object.value).valid?
              when RDF::SCHEMA.Duration
                value = stmt.object.value
                value = "P#{value}" unless value.start_with?("P")
                stmt.object.datatype == RDF::SCHEMA.Duration ||
                stmt.object.is_a?(RDF::Literal::Duration) ||
                stmt.object.simple? && RDF::Literal::Duration.new(value).valid?
              when RDF::SCHEMA.Time
                stmt.object.datatype == RDF::SCHEMA.Time ||
                stmt.object.is_a?(RDF::Literal::Time) ||
                stmt.object.simple? && RDF::Literal::Time.new(stmt.object.value).valid?
              when RDF::SCHEMA.Number
                stmt.object.is_a?(RDF::Literal::Numeric) ||
                [RDF::SCHEMA.Number, RDF::SCHEMA.Float, RDF::SCHEMA.Integer].include?(stmt.object.datatype) ||
                stmt.object.simple? && RDF::Literal::Integer.new(stmt.object.value).valid? ||
                stmt.object.simple? && RDF::Literal::Double.new(stmt.object.value).valid?
              when RDF::SCHEMA.Float
                stmt.object.is_a?(RDF::Literal::Double) ||
                [RDF::SCHEMA.Number, RDF::SCHEMA.Float].include?(stmt.object.datatype) ||
                stmt.object.simple? && RDF::Literal::Double.new(stmt.object.value).valid?
              when RDF::SCHEMA.Integer
                stmt.object.is_a?(RDF::Literal::Integer) ||
                [RDF::SCHEMA.Number, RDF::SCHEMA.Integer].include?(stmt.object.datatype) ||
                stmt.object.simple? && RDF::Literal::Integer.new(stmt.object.value).valid?
              when RDF::SCHEMA.URL
                stmt.object.datatype == RDF::SCHEMA.URL ||
                stmt.object.datatype == RDF::XSD.anyURI ||
                stmt.object.simple? && RDF::Literal::AnyURI.new(stmt.object.value).valid?
              else
                # If this is an XSD range, look for appropriate literal
                if range.start_with?(RDF::XSD.to_s)
                  if stmt.object.datatype == RDF::URI(range)
                    true
                  else
                    # Valid if cast as datatype
                    stmt.object.simple? && RDF::Literal(stmt.object.value, :datatype => RDF::URI(range)).valid?
                  end
                else
                  # Otherwise, presume that the range refers to a typed resource
                  false
                end
              end
            end # any?
          elsif %w(True False).map {|v| RDF::SCHEMA.to_uri + v}.include?(stmt.object) && ranges.include?(RDF::SCHEMA.Boolean)
            true # Special case for schema boolean resources
          else # Object is a resource
            # If object is also a subject, it must have appropriate types defined
            statements = graph.query(:subject => stmt.object).to_a
            types = statements.select {|s| s.predicate == RDF.type}.map(&:object)
            statements.empty? || ranges.any? {|d| types.include?(d)}
          end
          unless any_okay
            ((messages[:property] ||= {})[curie] ||= []) <<
              "Object must have some type defined as range (#{ranges.map {|d| get_curie(d) || d}.join(',')})"
          end
        end
      end

      messages[:class].each {|k, v| messages[:class][k] = v.uniq} if messages[:class]
      messages[:property].each {|k, v| messages[:property][k] = v.uniq} if messages[:property]
      messages
    end
    module_function :lint

    private
    EXPANDED_DEFS = VOCAB_DEFS["Vocabularies"].merge("rdf" => RDF.to_uri.to_s, "rdfs" => RDF::RDFS.to_uri.to_s)
    def get_curie(uri)
      pfx, v_uri = EXPANDED_DEFS.detect {|k, v| uri.to_s.start_with?(v)}
      return nil unless pfx
      uri.to_s.sub(v_uri, "#{pfx}:")
    end
    module_function :get_curie
  end
end