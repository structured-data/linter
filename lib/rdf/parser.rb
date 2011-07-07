module RDF::Linter
  module Parser

    # Parse the an input file and re-serialize based on params and/or content-type/accept headers
    def parse(reader_opts)
      graph = RDF::Graph.new
      format = reader_opts[:format]

      case
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

      writer_opts = reader_opts
      writer_opts[:haml] = LINTER_HAML
      writer_opts[:haml_options] = {:ugly => false}
      ["text/html", graph.dump(:rdfa, writer_opts)]
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