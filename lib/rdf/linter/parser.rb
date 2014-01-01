require 'rdf/linter/writer'
require 'rdf/linter/vocab_defs'
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
      
      # Perform some actual linting on the graph
      @lint_messages = lint(graph)

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
        uri, defn = VOCAB_DEFS["Classes"].detect {|k,v| k == cls}
        unless defn
          # No type definition found for class
          pfx, uri = VOCAB_DEFS["Vocabularies"].detect {|k, v| cls.start_with?(v)}
          next unless pfx
          (messages[:class] ||= {})[cls.sub(uri, "#{pfx}:")] = "No class definition found"
        end
      end

      # Check for defined predicates in known vocabularies
      graph.statements.map(&:predicate).uniq do |pred|
        prop = pred.to_s
        uri, defn = VOCAB_DEFS["Properties"].detect {|k,v| k == prop}
        unless defn
          # No type definition found for class
          pfx, uri = VOCAB_DEFS["Vocabularies"].detect {|k, v| prop.start_with?(v)}
          next unless pfx
          (messages[:property] ||= {})[prop.sub(uri, "#{pfx}:")] = "No property definition found"
        end
      end
      
      messages
    end
    module_function :lint
  end
end