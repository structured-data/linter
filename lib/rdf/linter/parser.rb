require 'rdf/linter/writer'
require 'nokogiri'

module RDF::Linter
  module Parser

    # Parse the an input file and re-serialize based on params and/or content-type/accept headers
    def parse(reader_opts)
      graph = RDF::Graph.new
      format = reader_opts[:format]
      reader_opts[:prefixes] ||= {}
      reader_opts[:rdf_terms] = true unless reader_opts.has_key?(:rdf_terms)

      reader = case
      when reader_opts[:tempfile]
        RDF::Reader.for(format).new(reader_opts[:tempfile], reader_opts) {|r| graph << r}
      when  reader_opts[:content]
        @content = reader_opts[:content]
        RDF::Reader.for(format).new(@content, reader_opts) {|r| graph << r}
      when reader_opts[:base_uri]
        RDF::Reader.open(reader_opts[:base_uri], reader_opts) {|r| graph << r}
      else
        return ["text/html", ""]
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
      
      writer_opts = reader_opts
      writer_opts[:base_uri] ||= reader.base_uri.to_s if reader.base_uri
      writer_opts[:prefixes][:ogt] = "http://types.ogp.me/ns#"
      
      # Move elements with class `snippet` to the front of the root element
      html = RDF::Linter::Writer.buffer(writer_opts) {|w| w << graph}
      ["text/html", html]
    rescue RDF::ReaderError => e
      @error = "RDF::ReaderError: #{e.message}"
      puts @error  # to log
      ["text/html", @error]
    rescue
      raise unless settings.environment == :production
      @error = "#{$!.class}: #{$!.message}"
      puts @error  # to log
      ["text/html", @error]
    end
  end
end