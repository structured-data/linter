require 'sinatra'
require 'sinatra/linkeddata'   # Can't use this, as we may need to set by hand, and have to pass options to the serializer
require 'sinatra/partials'
require 'erubis'
require 'find'
require 'rdf/microdata'
#require 'rdf/all'
require 'net/http'
require 'uri'

module RDF
  module Linter
    require 'rdf/linter/parser'
    require 'rdf/linter/extensions'
    autoload :VERSION,      'rdf/linter/version'
    autoload :Schema,       'rdf/linter/schema'

    class Application < Sinatra::Base
      APP_DIR = File.expand_path("../..", File.dirname(__FILE__))
      PUB_DIR = File.join(APP_DIR, 'public')
      LINTER_DIR = File.join(APP_DIR, 'lib', 'rdf', 'linter')
      SNIPPET_DIR = File.join(LINTER_DIR, 'snippets')

      #register Sinatra::LinkedData
      helpers Sinatra::Partials
      #use Rack::LinkedData::ContentNegotiation, :default => "text/html"
      set :root, APP_DIR
      set :views, ::File.expand_path('../linter/views',  __FILE__)
      set :app_name, "Structured Data Linter"

      before do
        puts "[#{request.path_info}], #{params.inspect}"
      end

      get '/' do
        linter
      end

      post '/' do
        linter
      end

      get '/about/' do
        @title = "About the Linter"
        cache_control :public, :must_revalidate, :max_age => 60
        erb :about
      end

      get '/examples/' do
        @title = "Markup Examples"
        cache_control :public, :must_revalidate, :max_age => 60
        erb :examples, :locals => {
          :root => RDF::URI(request.url).join("/").to_s,
        }
      end

      get '/examples/google-rs/:name/' do
        cache_control :public, :must_revalidate, :max_age => 60
        @title = "Google RS #{params[:name]}"
        erb :rs_example, :locals => {
          :head => :examples,
          :name => params[:name],
          :root => RDF::URI(request.url).join("/").to_s
        }
      end

      get '/examples/google-rs/:file' do
        cache_control :public, :must_revalidate, :max_age => 60
        send_file File.join(APP_DIR, "google-rs/#{params[:file]}"), :type => :html
      end

      get '/examples/good-relations/:name/' do
        cache_control :public, :must_revalidate, :max_age => 60
        @title = "Good Relations #{params[:name]}"
        erb :gr_example, :locals => {
          :head => :examples,
          :name => params[:name],
          :root => RDF::URI(request.url).join("/").to_s
        }
      end

      get '/examples/good-relations/:file' do
        cache_control :public, :must_revalidate, :max_age => 60
        send_file File.join(APP_DIR, "good-relations/#{params[:file]}"), :type => :html
      end

      get '/examples/schema.org/:name/' do
        cache_control :public, :must_revalidate, :max_age => 60
        @title = "Schema.org #{params[:name]}"
        
        # Find examples using this class
        examples = {}
        Dir.glob(File.expand_path("../../../schema-org-rdf/examples/*/*.{microdata,rdfa,jsonld}", __FILE__)) do |path|
          ex_num = if md = path.split('/').last.match(/^\w+-(\w+)\.\w+$/)
            md[1]
          else
            "Base"
          end
          fmt = File.extname(path)[1..-1]

          File.open(path, "r", 0, :encoding => Encoding::UTF_8) do |file|
            src = if fmt == "jsonld"
              file.read
            else
              xp = if fmt == "microdata"
                %(//*[@itemtype="http://schema.org/#{params[:name]}"])
              else
                %(//*[@typeof="#{params[:name]}"])
              end
              doc = Nokogiri::HTML.parse(file.read)
              p = doc.at_xpath(xp)
              puts "check xpath #{xp}: #{p.inspect}"
              next unless p
              doc.at_xpath("/html/body/*").to_s
            end
            examples[ex_num] ||= {}
            examples[ex_num][fmt] = {
              :path => RDF::URI(request.url).join("../" + File.basename(path)),
              :src => src
            }
          end
        end

        puts "examples for #{@title}: #{examples.inspect}"
        erb :schema_example, :locals => {
          :head => :examples,
          :name => params[:name],
          :examples => examples,
          :root => RDF::URI(request.url).join("/").to_s
        }
      end

      get '/examples/schema.org/:file' do
        cache_control :public, :must_revalidate, :max_age => 60
        file = nil
        Find.find(File.join(APP_DIR, "schema-org-rdf")) do |f|
          file ||= f if File.file?(f) && f.match(/#{params[:file]}$/)
        end
        if file
          send_file file, :type => file =~ /jsonld/ ? :jsonld : :html
        else
          status 401
          body "Could not find schema example #{params[:file]}"
        end
      end

      # Display list of snippets
      get '/snippets/' do
        @title = "Snippet definitions"
        cache_control :public, :must_revalidate, :max_age => 60
        erb :snippets, :locals => {
          :root => RDF::URI(request.url).join("/").to_s,
        }
      end

      get '/snippets/:name' do
        cache_control :public, :must_revalidate, :max_age => 60
        @title = params[:name]
        erb :snippet, :locals => {
          :name => params[:name],
          :root => RDF::URI(request.url).join("/").to_s
        }
      end

      private

      include Parser

      # Handle GET/POST /
      def linter
        params["in_fmt"] = "all" if params["in_fmt"].to_s.empty?
        reader_opts = {
          :base_uri => params["url"],
          :validate => params["validate"],
          :format   => params["in_fmt"].to_sym,
        }
        reader_opts[:base_uri] = params["url"].strip if params["url"]
        reader_opts[:debug] = @debug = [] if params["debug"]
        reader_opts[:tempfile] = params["datafile"] unless params["datafile"].to_s.empty?
        reader_opts[:content] = params["content"] unless params["content"].to_s.empty?
        reader_opts[:matched_templates] = []

        root = RDF::URI(request.url).join("/").to_s
        puts "request.url: #{request.url}, request.path: #{request.path}, root URI: #{root}"

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
        @output ||= "<p>No formats detected.</p>"
        @title = "Structured Data Linter"
        erb :linter, :locals => {
          :head => :linter,
          :root => RDF::URI(request.url).join("/").to_s,
          :matched_templates => reader_opts[:matched_templates].uniq
        }
      end
    end

    def self.debug?; @debug; end
    def self.debug=(value); @debug = value; end
  end
end
