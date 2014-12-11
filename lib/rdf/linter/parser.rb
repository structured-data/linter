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
    # @return [Array(RDF::Graph, String, RDF::URI)] graph, messages, base_uri
    def parse(reader_opts)
      logger = reader_opts[:logger] ||= begin
        l = Logger.new(STDOUT)  # In case we're not invoked from rack
        l.level = ::RDF::Linter.debug? ? Logger::DEBUG : Logger::INFO
        l
      end
      RDF::Reasoner.apply(:rdfs, :schema)
      graph = RDF::Repository.new
      reader_opts[:prefixes] ||= {}
      reader_opts[:rdf_terms] = true unless reader_opts.has_key?(:rdf_terms)

      reader = case
      when reader_opts[:tempfile]
        request.logger.info "Parse input file #{reader_opts[:tempfile].inspect} with format #{reader_opts[:format]}"
        RDF::All::Reader.new(reader_opts[:tempfile], reader_opts) {|r| graph << r}
      when reader_opts[:content]
        request.logger.info "Parse form data with format #{reader_opts[:format]}"
        RDF::All::Reader.new(reader_opts[:content], reader_opts) {|r| graph << r}
      when reader_opts[:base_uri]
        request.logger.info "Open url <#{reader_opts[:base_uri]}> with format #{reader_opts[:format]}"
        RDF::All::Reader.open(reader_opts[:base_uri], reader_opts) {|r| graph << r}
      else
        raise RDF::ReaderError, "Expected one of tempfile, content or base_uri"
      end

      # Expand graph with entailed types
      expand_graph(graph)

      # Perform some actual linting on the graph
      lint_messages = lint(graph)
      [graph, lint_messages, reader.base_uri]
    end
    module_function :parse

    ##
    # Expand a graph with entailed types based on range/domain and subClassOf
    # @param [RDF::Graph] graph
    def expand_graph(graph)
      RDF::Reasoner.apply(:rdfs, :schema)
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
          vtype = RDF::Vocabulary.find_term(type) rescue nil
          (vtype ? vtype.entail(:subClassOf) : []).each do |t|
            graph << RDF::Statement.new(subj, RDF.type, RDF::URI(t), :context => CTX)
          end
        end
      end
    end
    module_function :expand_graph

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
        if term && term.class?
          # Warn against using a deprecated term
          superseded = term.attributes['schema:supersededBy']
          (messages[:class] ||= {})[pname] = ["Term is superseded by #{superseded}"] if superseded
        else
          (messages[:class] ||= {})[pname] = ["No class definition found"] unless vocab.nil? || [RDF::RDFV, RDF::RDFS].include?(vocab)
        end
      end

      # Check for defined predicates in known vocabularies and domain/range
      resource_types = {}
      graph.each_statement do |stmt|
        vocab = RDF::Vocabulary.find(stmt.predicate)
        term = (RDF::Vocabulary.find_term(stmt.predicate) rescue nil) if vocab
        pname = term ? term.pname : stmt.predicate.pname

        # Must be a defined property
        if term && term.property?
          # Warn against using a deprecated term
          superseded = term.attributes['schema:supersededBy']
          (messages[:property] ||= {})[pname] = ["Term is superseded by #{superseded}"] if superseded
        else
          ((messages[:property] ||= {})[pname] ||= []) << "No property definition found" unless vocab.nil?
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
           "Subject #{show_resource(stmt.subject, graph)} not compatible with domain (#{Array(term.domain).map {|d| d.pname|| d}.join(',')})"
          else
            "Subject #{show_resource(stmt.subject, graph)} not compatible with domainIncludes (#{term.domainIncludes.map {|d| d.pname|| d}.join(',')})"
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
           "Object #{show_resource(stmt.object, graph)} not compatible with range (#{Array(term.range).map {|d| d.pname|| d}.join(',')})"
          else
            "Object #{show_resource(stmt.object, graph)} not compatible with rangeIncludes (#{term.rangeIncludes.map {|d| d.pname|| d}.join(',')})"
          end
        end
      end

      messages[:class].each {|k, v| messages[:class][k] = v.uniq} if messages[:class]
      messages[:property].each {|k, v| messages[:property][k] = v.uniq} if messages[:property]
      messages
    end
    module_function :lint

  private

    # Show resource in diagnostic output
    def show_resource(resource, graph)
      if resource.node?
        resource.to_ntriples + '(' +
          graph.query(subject: resource, predicate: RDF.type).
            map {|s| s.object.uri? ? s.object.pname : s.object.to_ntriples}
            .join(',') +
          ')'
      else
        resource.to_ntriples
      end
    end
    module_function :show_resource
  end
end