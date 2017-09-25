require 'rdf/linter/writer'
require 'rdf/xsd'
require 'nokogiri'

module RDF::Linter
  module Parser
    CTX = RDF::URI("http://linter.structured-data.org/#tbox")

    # Parse the an input file based on params and/or content-type header
    # @param [Hash{Symbol => Object}] reader_opts
    #   options also passed to reader
    # @option options [Symbol] :format RDF Reader format symbol for reading content
    # @option options [Hash{Symbol => RDF::URI}] :prefixes passed to reader and writer
    # @option options [Tempfile] :tempfile location of content
    # @option options [String] :content literal content
    # @option options [RDF::URI] :base_uri location of file, or where to treat content as having been located.
    # @return [Array(RDF::Graph, Hash{Symbol => Array(String)}, RDF::URI)] graph, messages, base_uri
    def parse(reader_opts)
      logger = reader_opts[:logger] ||= begin
        l = Logger.new(STDOUT)  # In case we're not invoked from rack
        l.level = ::RDF::Linter.debug? ? Logger::DEBUG : Logger::INFO
        l
      end

      # Readers now use :logger for debug output, which may be an array
      reader_opts = reader_opts.merge(logger: reader_opts.fetch(:debug, []))
      RDF::Reasoner.apply(:rdfs, :schema)
      graph = RDF::Repository.new
      reader_opts[:prefixes] ||= {}
      reader_opts[:validate] = true
      reader_opts[:rdf_terms] = true unless reader_opts.has_key?(:rdf_terms)
      lint_messages = {}

      # Try parsing first with validation mode, and if an error is raised, collect messages and re-parse without validation mode
      begin
        reader = case
        when reader_opts[:tempfile]
          logger.info "Parse input file #{reader_opts[:tempfile].inspect} with format #{reader_opts[:format]}"
          reader_opts[:base_uri] ||= "http://example.org/"  # Allow relative URIs
          reader_class = RDF::Reader.for(reader_opts[:format] || reader_opts) || RDF::RDFa::Reader
          reader_class.new(reader_opts[:tempfile], reader_opts) { |r| graph << r}
        when reader_opts[:content]
          logger.info "Parse form data with format #{reader_opts[:format]}"
          reader_opts[:base_uri] ||= "http://example.org/"  # Allow relative URIs
          reader_class = RDF::Reader.for(reader_opts[:format] || reader_opts) || RDF::RDFa::Reader
          reader_class.new(reader_opts[:content], reader_opts) { |r| graph << r}
        when reader_opts[:base_uri]
          logger.info "Open url <#{reader_opts[:base_uri]}> with format #{reader_opts[:format]}"
          RDF::Reader.open(reader_opts[:base_uri], reader_opts) { |r| graph << r}
        else
          raise RDF::ReaderError, "Expected one of tempfile, content or base_uri"
        end
      rescue RDF::ReaderError => e
        if reader_opts[:validate]
          reader_opts.delete(:validate)
          lint_messages[:validation] = {reader_opts[:base_uri] =>  [e.message] + reader_opts[:logger]}
          retry
        else
          return [nil, lint_messages, (reader.base_uri if reader && reader.base_uri)]
        end
      end

      # Expand graph with entailed types
      expand_graph(graph)

      # Perform some actual linting on the graph
      lint_messages.merge!(graph.lint)
      [graph, lint_messages, reader]
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

      # Use Reasoner entailment
      graph.entail!
    end
    module_function :expand_graph

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