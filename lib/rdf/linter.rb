require 'sinatra'
require 'sinatra/linkeddata'   # Can't use this, as we may need to set by hand, and have to pass options to the serializer
require 'sinatra/partials'
require 'erubis'
require 'rdf/microdata'
require 'json/ld'

module RDF
  module Linter
    autoload :VERSION,      'rdf/linter/version'
    autoload :LINTER_HAML,  'rdf/linter/rdfa_template'

    class Application < Sinatra::Base
      #register Sinatra::LinkedData
      helpers Sinatra::Partials
      #use Rack::LinkedData::ContentNegotiation, :default => "text/html"
      set :views, ::File.expand_path('../linter/views',  __FILE__)

      before do
        puts "[#{request.path_info}], #{params.inspect}"
      end

      get '/' do
        linter
      end

      post '/' do
        linter
      end

      get '/about' do
        cache_control :public, :must_revalidate, :max_age => 60
        erubis :about, :locals => {:title => "About the Structured Data Linter"}
      end

      private

      # Handle GET/POST /
      def linter
        params["in_fmt"] = "all" if params["in_fmt"].to_s.empty?
        reader_opts = {
          :prefixes => {},
          :base_uri => params["uri"],
          :validate => params["validate"],
          :format   => params["in_fmt"].to_sym,
        }
        reader_opts[:debug] = @debug = [] if params["debug"]
        reader_opts[:tempfile] = params["datafile"] unless params["datafile"].to_s.empty?
        reader_opts[:content] = params["content"] unless params["content"].to_s.empty?
        
        content_type, content = parse(reader_opts)
        @output = content unless content == @error
        erubis :linter, :locals => {:title => "Structured Data Linter", :head => :linter}
      end

      # Parse the an input file and re-serialize based on params and/or content-type/accept headers
      def parse(reader_opts)
        graph = RDF::Graph.new
        format = reader_opts[:format]

        case
        when reader_opts[:tempfile]
          puts "Parse input file #{reader_opts[:tempfile].inspect} with format #{format}"
          reader = RDF::Reader.for(format).new(reader_opts[:tempfile], reader_opts) {|r| graph << r}
        when  reader_opts[:content]
          puts "Parse form data with format #{format}"
          @content = reader_opts[:content]
          reader = RDF::Reader.for(format).new(@content, reader_opts) {|r| graph << r}
        when reader_opts[:base_uri]
          puts "Open uri <#{reader_opts[:base_uri]}> with format #{format}"
          reader = RDF::Reader.open(reader_opts[:base_uri], reader_opts) {|r| graph << r}
          params["in_fmt"] = reader.class.to_sym if format.nil? || format == :content
        else
          return ["text/html", ""]
        end

        writer_opts = reader_opts
        haml = LINTER_HAML.dup
        root = RDF::URI(request.url).join("/").to_s
        puts "requrest.url: #{request.url}, request.path: #{request.path}, root URI: #{root}"
        haml[:doc] = haml[:doc].gsub(/--root--/, root)
        writer_opts[:haml] = haml
        writer_opts[:haml_options] = {:ugly => false}
        ["text/html", graph.dump(:rdfa, writer_opts)]
      rescue RDF::ReaderError => e
        @error = "RDF::ReaderError: #{e.message}"
        puts @error  # to log
        [content_type, @error] # XXX
      rescue
        raise unless settings.environment == :production
        @error = "#{$!.class}: #{$!.message}"
        puts @error  # to log
        ["text/html", @error] # XXX
      end
    end
  end

  module Util::File
    ##
    # Override to use Net::HTTP, which means that it only opens URIs.
    #
    # @param [String] filename_or_url to open
    # @param  [Hash{Symbol => Object}] options
    #   any options to pass through to the underlying UUID library
    # @return [IO] File stream
    # @yield [IO] File stream
    def self.open_file(filename_or_url, options = {}, &block)
      Kernel.open(filename_or_url, {"User-Agent" => "Ruby Structured Data Linter #{VERSION} (http://linter.greggkellogg.net/)"}, &block)
    end
  end
end
