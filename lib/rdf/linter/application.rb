require 'sinatra'
require 'sinatra/linkeddata'
require 'sinatra/partials'
require 'erubis'

module RDF::Linter
  class Application < Sinatra::Base
    APP_DIR = File.expand_path("../../..", File.dirname(__FILE__))
    PUB_DIR = File.join(APP_DIR, 'public')
    LINTER_DIR = File.join(APP_DIR, 'lib', 'rdf', 'linter')
    SNIPPET_DIR = File.join(LINTER_DIR, 'snippets')

    #register Sinatra::LinkedData
    helpers Sinatra::Partials
    #use Rack::LinkedData::ContentNegotiation, :default => "text/html"
    set :root, APP_DIR
    set :views, ::File.expand_path('../views',  __FILE__)
    set :app_name, "Structured Data Linter"

    before do
      $logger.info "[#{request.path_info}], " +
        "#{request.accept}, " +
        "#{params.inspect}, " +
        "#{request.accept.inspect}" if $logger
    end

    # Get "/" either returns the main linter page or linted markup
    #
    # @method get_linter
    # @overload get "/", params
    # @see {#linter}
    get '/' do
      linter params
    end

    # Get "/" returns linted markup
    #
    # @method post_linter
    # @overload post "/", params
    # @see {#linter}
    post '/' do
      linter params
    end

    # Return about page
    # @method get_about
    # @overload get "/about/"
    get '/about/' do
      @title = "About the Linter"
      cache_control :public, :must_revalidate, :max_age => 60
      erb :about
    end

    # Return markup examples
    # @method get_examples
    # @overload get "/examples/"
    get '/examples/' do
      @title = "Markup Examples"
      cache_control :public, :must_revalidate, :max_age => 60
      erb :examples, :locals => {
        :root => RDF::URI(request.url).join("/").to_s,
      }
    end

    # Return a specific Google Rich Snippet example
    # @method get_rs_example
    # @overload get "/examples/google-rs/:name/"
    # @param [String] name Name of the example to return
    get '/examples/google-rs/:name/' do
      cache_control :public, :must_revalidate, :max_age => 60
      @title = "Google RS #{params[:name]}"
      erb :rs_example, :locals => {
        :head => :examples,
        :name => params[:name],
        :root => RDF::URI(request.url).join("/").to_s
      }
    end

    # Return source of a specific Google Rich Snippet example
    # @method get_rs_example
    # @overload get "/examples/google-rs/:file"
    # @param [String] file Name of the example to return
    get '/examples/google-rs/:file' do
      cache_control :public, :must_revalidate, :max_age => 60
      file_loc = params[:file]
      send_file File.join(APP_DIR, "google-rs/#{file_loc}"),
        :type => (params[:file].end_with?(".jsonld") ? :jsonld : :html),
        :charset => "utf-8"
    end

    # Return a specific Good Relations example
    # @method get_gr_example
    # @overload get "/examples/good-relations/:name/"
    # @param [String] name Name of the example to return
    get '/examples/good-relations/:name/' do
      cache_control :public, :must_revalidate, :max_age => 60
      @title = "Good Relations #{params[:name]}"
      erb :gr_example, :locals => {
        :head => :examples,
        :name => params[:name],
        :root => RDF::URI(request.url).join("/").to_s
      }
    end

    # Return source of a specific Good Relations example
    # @method get_gr_example
    # @overload get "/examples/good-relations/:file"
    # @param [String] file Name of the example to return
    get '/examples/good-relations/:file' do
      cache_control :public, :must_revalidate, :max_age => 60
      send_file File.join(APP_DIR, "good-relations/#{params[:file]}"),
        :type => (params[:file].end_with?(".jsonld") ? :jsonld : :html),
        :charset => "utf-8"
    end

    # Return a specific schema.org example
    # @method get_sc_example
    # @overload get "/examples/schema.org/:name/"
    # @param [String] name Name of the example to return
    get '/examples/schema.org/:name/' do
      cache_control :public, :must_revalidate, :max_age => 60
      @title = "Schema.org #{params[:name]}"
      
      # Find examples using this class
      examples = {}
      Dir.glob(File.join(APP_DIR, "schema-org-rdf/examples/**/#{params[:name]}*.{microdata,rdfa,jsonld}")) do |path|
        md = path.split('/').last.match(/^\w+(?:-(\w+))?\.\w+$/)
        ex_num = md[1]
        ex_num ||= "Basic"
        fmt = File.extname(path)[1..-1].to_sym

        File.open(path, "r", :encoding => Encoding::UTF_8) do |file|
          src = if fmt == :jsonld
            file.read
          else
            doc = Nokogiri::HTML.parse(file.read)
            doc.at_xpath("/html/body/*").to_s
          end
          examples[ex_num] ||= {}
          examples[ex_num][fmt] = {
            :path => RDF::URI(request.url).join("../" + File.basename(path)),
            :src => src
          }
        end
      end

      $logger.info "examples for #{@title}: #{examples.keys.inspect}"
      erb :schema_example, :locals => {
        :head => :examples,
        :name => params[:name],
        :examples => examples,
        :root => RDF::URI(request.url).join("/").to_s
      }
    end

    # Return source of a specific schema.org example
    # @method get_sc_example
    # @overload get "/examples/good-relations/:file"
    # @param [String] file Name of the example to return
    get '/examples/schema.org/:file' do
      cache_control :public, :must_revalidate, :max_age => 60
      file_loc = params[:file].end_with?(".html") ? params[:file][0..-6] : params[:file]
      file = nil
      Find.find(File.join(APP_DIR, "schema-org-rdf")) do |f|
        file ||= f if File.file?(f) && f.match(/#{file_loc}$/)
      end
      if file
        send_file file,
          :type => (file.end_with?(".jsonld") ? :jsonld : :html),
          :charset => "utf-8"
      else
        status 401
        body "Could not find schema example #{params[:file]}"
      end
    end

    # Display list of snippets
    # @method get_snipptes
    # @overload get "/snippets/"
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
    # @param {Hash} params
    # @option params [String] :base_uri
    #   Base URI for decoding markup, defaluts to `:url` if present
    # @option params [String] :content
    #   Markup specified inline
    # @option params [String] :datafile
    #   Location of uploaded file containing markup
    # @option params [Boolean] :debug
    #   Return verbose debug output
    # @option params [String] :format ("all")
    #   Format to use when parsing file, defaults to parsing with all
    #   appropriate readers
    # @option params [String] :url
    #   Location of resource containing markup
    # @option params [Boolean] :validate
    #   Perform strict validation of markup
    def linter(params)
      params["format"] = "all" if params["format"].to_s.empty?
      reader_opts = {
        :base_uri => params["url"],
        :validate => params["validate"],
        :format   => params["format"].to_sym,
      }
      reader_opts[:base_uri] = params["url"].strip if params["url"]
      reader_opts[:debug] = @debug = [] if params["debug"]
      reader_opts[:tempfile] = params["datafile"] unless params["datafile"].to_s.empty?
      reader_opts[:content] = params["content"] unless params["content"].to_s.empty?
      reader_opts[:encoding] = Encoding::UTF_8  # Read files as UTF_8
      reader_opts[:matched_templates] = []

      root = RDF::URI(request.url).join("/").to_s
      $logger.debug "request.url: #{request.url}, request.path: #{request.path}, root URI: #{root}"

      case
      when reader_opts[:tempfile]
        $logger.info "Parse input file #{reader_opts[:tempfile].inspect} with format #{reader_opts[:format]}"
      when  reader_opts[:content]
        $logger.info "Parse form data with format #{reader_opts[:format]}"
        @content = reader_opts[:content]
      when reader_opts[:base_uri]
        $logger.info "Open url <#{reader_opts[:base_uri]}> with format #{reader_opts[:format]}"
      end

      content_type, status, content = parse(reader_opts)
      content.gsub!(/--root--/, root)
      @output = content unless content == @error
      @output ||= "<p>No formats detected.</p>"
      @title = "Structured Data Linter"
      status status
      content_type content_type
      erb :linter, :locals => {
        :head => :linter,
        :root => RDF::URI(request.url).join("/").to_s,
        :matched_templates => reader_opts[:matched_templates].uniq
      }
    end
  end
end
