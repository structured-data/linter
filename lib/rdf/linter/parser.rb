require 'rdf/linter/writer'
require 'rdf/linter/vocab_defs'
require 'nokogiri'

module RDF::Linter
  module Parser

    # Parse the an input file and re-serialize based on params and/or content-type/accept headers
    def parse(reader_opts)
      $logger ||= begin
        logger = Logger.new(STDOUT)  # In case we're not invoked from rack
        logger.level ::RDF::Linter.debug? ? Logger::DEBUG : Logger::INFO
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
        return ["text/html", ""]
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

      writer_opts = reader_opts
      writer_opts[:base_uri] ||= reader.base_uri.to_s unless reader.base_uri.to_s.empty?
      writer_opts[:prefixes][:ogt] = "http://types.ogp.me/ns#"

      #breakpoint

      # Move elements with class `snippet` to the front of the root element
      html = RDF::Linter::Writer.buffer(writer_opts) {|w| w << graph}
      ["text/html", 200, html]
    rescue RDF::ReaderError => e
      @error = "RDF::ReaderError: #{e.message}"
      $logger.error @error
      $logger.debug e.backtrace.join("\n")
      ["text/html", 400, @error]
    rescue OpenURI::HTTPError => e
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
    
    # Create JSON representation of classes and properties in a vocabulary
    # If the vocabulary definition is not located at `url` set it in `location`.
    #
    # Extracts class/property IRIs and labels for vocabulary terms from
    # OWL/RDFS description of vocabulary
    #
    # @param [RDF::URL] url
    # @param [String] prefix
    # @param [Hash{Symbol => Object}] options
    # @option options [RDF::URL] :location (nil)
    # @option options [IO] :io (STDOUT)
    # @option options [Symbol] :format
    def self.vocab_def(url, prefix, options = {})
      io = options[:io] || STDOUT
      location = options[:location] || url
      require 'json'
      require 'sparql'
      defs = {
        "Vocabularies" => {prefix => url},
        "Classes" => {},
        "Properties" => {},
        "Datatypes" => {},
      }
      repo = RDF::Repository.load(location, options)
      # FIXME: problem with SPARQL FILTER command
      vocab_query = %{
        PREFIX rdf: <#{RDF.to_uri}>
        PREFIX rdfs: <#{RDF::RDFS.to_uri}>
        SELECT ?subject ?type ?label
        WHERE {
          ?subject a ?type
          OPTIONAL {?subject rdfs:label ?label}
          #FILTER (?type IN (rdf:Property, rdfs:Class, rdf:DataType))
        }
        ORDER BY ?subject
      }
      SPARQL.execute(vocab_query, repo).each do |soln|
        section = case soln.type
        when RDF.Property then "Properties"
        when RDF::RDFS.Class then "Classes"
        when RDF::RDFS.Datatype then "Datatypes"
        else next
        end
        defs[section][soln.subject] = {:vocab => prefix, :label => (soln[:label] || soln.subject.to_s.split(/[\/#]/).last)}
      end

      defs.keys.each {|k| defs.delete(k) if defs[k].empty?}
      # Serialize definitions
      io.puts defs.to_json(
        :indent       => "  ",
        :space        => " ",
        :space_before => "",
        :object_nl    => "\n",
        :array_nl     => "\n"
      )
    end
    
    # Create native representation of vocabulary definitions from JSON files
    def self.cook_vocabularies(io = STDOUT)
      require 'json'
      defs = {
        "Vocabularies" => {},
        "Classes" => {},
        "Properties" => {},
        "Datatypes" => {},
      }
      Dir.glob(File.join(File.dirname(__FILE__), "*.json")).each do |file|
        File.open(file) do |f|
          STDERR.puts "load #{file}"
          v = JSON.load(f)
          v.each do |sect, hash|
            raise "unknown section #{sect}" unless defs.has_key?(sect)
            v[sect].each do |name, defn|
              raise "attempt to redefine #{sect} definition of #{name}" if defs[sect].has_key?(name)
              defs[sect][name] = defn
            end
          end
        end
      end
    
      # Serialize definitions
      io.puts "# This file is automatically generated by #{__FILE__}"
      io.puts "module RDF::Linter::Parser"
      io.puts "  VOCAB_DEFS = " + defs.inspect
      io.puts "end"
    end
  end
end