require 'sinatra'
require 'sinatra/linkeddata'   # Can't use this, as we may need to set by hand, and have to pass options to the serializer
require 'sinatra/partials'
require 'erubis'
require 'rdf/microdata'
require 'json/ld'
require 'rdf/all'

module RDF
  module Linter
    require 'rdf/linter/parser'
    autoload :VERSION,      'rdf/linter/version'

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

      include Parser
      
      # Handle GET/POST /
      def linter
        params["in_fmt"] = "all" if params["in_fmt"].to_s.empty?
        reader_opts = {
          :prefixes => {},
          :base_uri => params["url"],
          :validate => params["validate"],
          :format   => params["in_fmt"].to_sym,
        }
        reader_opts[:debug] = @debug = [] if params["debug"]
        reader_opts[:tempfile] = params["datafile"] unless params["datafile"].to_s.empty?
        reader_opts[:content] = params["content"] unless params["content"].to_s.empty?
        
        root = RDF::URI(request.url).join("/").to_s
        puts "requrest.url: #{request.url}, request.path: #{request.path}, root URI: #{root}"

        case
        when reader_opts[:tempfile]
          puts "Parse input file #{reader_opts[:tempfile].inspect} with format #{reader_opts[:format]}"
        when  reader_opts[:content]
          puts "Parse form data with format #{reader_opts[:format]}"
          @content = reader_opts[:content]
        when reader_opts[:base_uri]
          puts "Open url <#{reader_opts[:base_uri]}> with format #{reader_opts[:format]}"
        end

        content_type, content = parse(reader_opts)
        content.gsub!(/--root--/, root)
        @output = content unless content == @error
        erubis :linter, :locals => {:title => "Structured Data Linter", :head => :linter}
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
