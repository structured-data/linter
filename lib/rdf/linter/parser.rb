require 'rdf/linter/writer'
require 'rdf/xsd'
require 'nokogiri'

module RDF::Linter
  module Parser
    CTX = RDF::URI("http://linter.structured-data.org/#tbox")

    # Parse the an input file and re-serialize based on params and/or content-type/accept headers
    # @param [Hash{Symbol => Object}] reader_opts
    #   options also passed to reader
    # @option options [Symbol] :format RDF Reader format symbol for reading content
    # @option options [Hash{Symbol => RDF::URI}] :prefixes passed to reader and writer
    # @option options [Tempfile] :tempfile location of content
    # @option options [String] :content literal content
    # @option options [RDF::URI] :base_uri location of file, or where to treat content as having been located.
    # @option options [Boolean] :output_format (:linter)
    #   Output format of graph, defaults to linter-based RDFa.
    # @return [Array(String, Integer, String)] Rack filter results
    def parse(reader_opts)
      $logger ||= begin
        logger = Logger.new(STDOUT)  # In case we're not invoked from rack
        logger.level = ::RDF::Linter.debug? ? Logger::DEBUG : Logger::INFO
        logger
      end
      RDF::Reasoner.apply(:rdfs, :schema)
      graph = RDF::Repository.new
      reader_opts[:prefixes] ||= {}
      reader_opts[:rdf_terms] = true unless reader_opts.has_key?(:rdf_terms)

      reader = case
      when reader_opts[:tempfile]
        RDF::All::Reader.new(reader_opts[:tempfile], reader_opts) {|r| graph << r}
      when reader_opts[:content]
        RDF::All::Reader.new(reader_opts[:content], reader_opts) {|r| graph << r}
      when reader_opts[:base_uri]
        RDF::All::Reader.open(reader_opts[:base_uri], reader_opts) {|r| graph << r}
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
        graph << RDF::Statement.new(statement.subject, RDF.type, RDF::URI("http://types.ogp.me/ns##{statement.object}"), :context => CTX)
      end
      
      # Similar, but using old namespace
      graph.query(:predicate => RDF::URI("http://opengraphprotocol.org/schema/type")) do |statement|
        graph << RDF::Statement.new(statement.subject, RDF.type, RDF::URI("http://opengraphprotocol.org/types/#{statement.object}"), :context => CTX)
      end

      # For subjects with no type, add types based on domain and range expressions, where this is feasible
      graph.each_subject do |subj|
        types = graph.query(:subject => subj, :predicate => RDF.type).map(&:object)
        # If there are no defined types, infer them from vocabulary definitionso on predicates of the subject or refering to the subject
        if types.empty?
          graph.query(:subject => subj) do |stmt|
            vocab = RDF::Vocabulary.find_term(stmt.predicate) rescue nil
            next unless vocab && vocab.property?
            domains = Array(vocab.domain || vocab.domainIncludes) - [RDF::OWL.Thing]
            next unless domains.length == 1
            # Add domain as a type for this if subject if it's uniq
            types << RDF::URI(domains.first)
          end

          graph.query(:object => subj) do |stmt|
            vocab = RDF::Vocabulary.find_term(stmt.predicate) rescue nil
            next unless vocab && vocab.property?
            ranges = Array(vocab.range || vocab.rangeIncludes) - [RDF::OWL.Thing]
            next if ranges.length != 1
            types << RDF::URI(ranges.first) 
          end
        end

        # Expand types using vocabulary entailment
        types.each do |type|
          entailed_types(type).each do |t|
            graph << RDF::Statement.new(subj, RDF.type, RDF::URI(t), :context => CTX)
          end
        end
      end

      # Perform some actual linting on the graph
      @lint_messages = lint(graph)

      writer = RDF::Writer.for(reader_opts[:output_format]) || RDF::Linter::Writer
      content_type = writer.format.content_type.first rescue 'text/html'

      writer_opts = reader_opts.dup
      writer_opts[:base_uri] ||= reader.base_uri.to_s unless reader.base_uri.to_s.empty?
      writer_opts[:debug] ||= [] if $logger.level <= Logger::DEBUG

      # Move elements with class `snippet` to the front of the root element
      result = writer.buffer(writer_opts) {|w| w << graph}
      writer_opts.fetch(:debug, []).each {|m| $logger.debug m}
      [content_type, 200, result]
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
      vtype = RDF::Vocabulary.find_term(type) rescue nil
      vtype ? vtype.entail(:subClassOf) : []
    end
    module_function :entailed_types

    # Use vocabulary definitions to lint contents of the graph for known vocabularies
    def lint(graph)
      RDF::Reasoner.apply(:rdfs, :schema)
      messages = {}

      # Check for defined classes in known vocabularies
      graph.query(:predicate => RDF.type) do |stmt|
        vocab = RDF::Vocabulary.find(stmt.object)
        term = (RDF::Vocabulary.find_term(stmt.object) rescue nil) if vocab
        pname = term ? term.pname : stmt.object.pname
        
        # Must be a defined term, not in RDF or RDFS vocabularies
        unless term && term.class?
          (messages[:class] ||= {})[pname] = ["No class definition found"] unless [RDF::RDFV, RDF::RDFS].include?(vocab)
        end
      end

      # Check for defined predicates in known vocabularies and domain/range
      resource_types = {}
      graph.each_statement do |stmt|
        vocab = RDF::Vocabulary.find(stmt.predicate)
        term = (RDF::Vocabulary.find_term(stmt.predicate) rescue nil) if vocab
        pname = term ? term.pname : stmt.predicate.pname

        # Must be a defined property
        unless term && term.property?
          ((messages[:property] ||= {})[pname] ||= []) << "No property definition found"
          next
        end

        # See if type of the subject is in the domain of this predicate
        resource_types[stmt.subject] ||= graph.query(subject: stmt.subject, predicate: RDF.type).
        map {|s| (t = (RDF::Vocabulary.find_term(s.object) rescue nil)) && t.entail(:subClassOf)}.
          flatten.
          uniq.
          compact

        unless term.domain_compatible?(stmt.subject, graph, :types => resource_types[stmt.subject])
          ((messages[:property] ||= {})[pname] ||= []) << if term.respond_to?(:domain)
           "Subject #{stmt.subject.to_ntriples} not compatable with domain (#{Array(term.domain).map {|d| d.pname|| d}.join(',')})"
          else
            "Subject #{stmt.subject.to_ntriples} not compatable with domainIncludes (#{term.domainIncludes.map {|d| d.pname|| d}.join(',')})"
          end
        end

        # Make sure that if ranges are defined, the object has an appropriate type
        resource_types[stmt.object] ||= graph.query(subject: stmt.object, predicate: RDF.type).
          map {|s| (t = (RDF::Vocabulary.find_term(s.object) rescue nil)) && t.entail(:subClassOf)}.
          flatten.
          uniq.
          compact if stmt.object.resource?

        unless term.range_compatible?(stmt.object, graph, :types => resource_types[stmt.object])
          ((messages[:property] ||= {})[pname] ||= []) << if term.respond_to?(:range)
           "Object #{stmt.object.to_ntriples} not compatable with range (#{Array(term.range).map {|d| d.pname|| d}.join(',')})"
          else
            "Object #{stmt.object.to_ntriples} not compatable with rangeIncludes (#{term.rangeIncludes.map {|d| d.pname|| d}.join(',')})"
          end
        end
      end

      messages[:class].each {|k, v| messages[:class][k] = v.uniq} if messages[:class]
      messages[:property].each {|k, v| messages[:property][k] = v.uniq} if messages[:property]
      messages
    end
    module_function :lint
  end
end