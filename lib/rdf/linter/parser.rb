require 'rdf/linter/rdfa_template'
require 'nokogiri'

module RDF::Linter
  module Parser

    # Parse the an input file and re-serialize based on params and/or content-type/accept headers
    def parse(reader_opts)
      graph = RDF::Graph.new
      format = reader_opts[:format]

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
      
      writer_opts = reader_opts
      writer_opts = reader_opts.merge(
        :standard_prefixes => true,
        :haml => LINTER_HAML,
        :base_uri => (reader.base_uri.to_s if reader.base_uri)
      )
      
      # Move elements with class `snippet` to the front of the root element
      doc = Nokogiri::XML.parse(graph.dump(:rdfa, writer_opts))
      snippets = doc.root.css('.snippet-content').map {|el| el.remove; el }
      leftover = doc.root.children.map {|el| el.remove; el}
      (snippets + leftover).each {|el| doc.root.add_child(el)}
      
      ["text/html", doc.root.to_html]
      #["text/html", graph.dump(:rdfa, writer_opts)]
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