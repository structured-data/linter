require 'sinatra'
require 'sinatra/linkeddata'
require 'sinatra/asset_pipeline'
require 'sprockets-helpers'
require 'uglifier'
require 'sass'
require 'erubis'

module RDF::Linter
  class Application < Sinatra::Base

    configure do
      set :root, APP_DIR
      set :public_folder, PUB_DIR
      set :views, ::File.expand_path('../views',  __FILE__)
      set :snippets, ::File.expand_path('../snippets',  __FILE__)
      set :app_name, "Structured Data Linter"
      enable :logging
      disable :raise_errors, :show_exceptions if settings.production?

      # Cache client requests
      #RestClient.enable Rack::Cache,
      #  verbose:     true,
      #  metastore:   "file:" + ::File.join(APP_DIR, "cache/meta"),
      #  entitystore: "file:" + ::File.join(APP_DIR, "cache/body")

      # Asset pipeline
      set :digest_assets, false

      # Include these files when precompiling assets
      set :assets_precompile, %w(*.js *.css *.ttf *.gif)

      # The path to your assets
      set :assets_paths, %w(assets/js assets/css assets/images)

      # CSS minification
      set :assets_css_compressor, :sass

      # JavaScript minification
      set :assets_js_compressor, :uglifier

      register Sinatra::AssetPipeline

      # Configure Sprockets::Helpers (if necessary)
      Sprockets::Helpers.configure do |config|
        config.environment = sprockets
        config.prefix      = assets_prefix
        config.digest      = digest_assets
        config.public_path = public_folder

        # Force to debug mode in development mode
        # Debug mode automatically sets
        # expand = true, digest = false, manifest = false
        config.debug       = true if development?
      end
    end

    configure :development do
      set :logging, ::Logger.new($stdout)
      require "better_errors"
      use BetterErrors::Middleware
      BetterErrors.application_root = APP_DIR
    end

    configure :test do
      set :logging, ::Logger.new(StringIO.new)
    end

    helpers do
      include Sprockets::Helpers

      # Set cache control
      def set_cache_header(options = {})
        options = {:max_age => ENV.fetch('max_age', 60*5)}.merge(options)
        cache_control(:public, :must_revalidate, options)
      end
    end

    before do
      request.logger.level = Logger::DEBUG unless settings.production?
      request.logger.info "#{request.request_method} [#{request.path_info}], " +
        params.merge(Accept: request.accept.map(&:to_s)).map {|k,v| "#{k}=#{v}"}.join(" ")
    end

    after do
      msg = "Status: #{response.status} (#{request.request_method} #{request.path_info}), Content-Type: #{response.content_type}"
      msg += ", Location: #{response.location}" if response.location
      request.logger.info msg
    end

    # Get "/" either returns the main linter page or linted markup
    #
    # @method get_linter
    # @overload get "/", params
    # @see {#linter}
    get '/' do
      respond_to do |wants|
        wants.other { erb :linter, locals: {head: :linter, root: url("/")} }
        wants.json { linter params }
      end
    end

    # POST "/" returns linted markup as JSON
    #
    # @method post_linter
    # @overload post "/", params
    # @see {#linter}
    post '/' do
      payload = params
      payload = JSON.parse(request.body.read) unless params['file']
      linter payload
    end

    # Return about page
    # @method get_about
    # @overload get "/about/"
    get '/about/' do
      @title = "About the Linter"
      set_cache_header
      erb :about
    end
    get '/about' do
      redirect '/about/'
    end

    # Return markup examples
    # @method get_examples
    # @overload get "/examples/"
    get '/examples/' do
      @title = "Markup Examples"
      set_cache_header
      erb :examples, locals: {root: url("/")}
    end
    get '/examples' do
      redirect '/examples/'
    end

    # Return a specific Google Rich Snippet example
    # @method get_rs_example
    # @overload get "/examples/google-rs/:name/"
    # @param [String] name Name of the example to return
    get '/examples/google-rs/:name/' do
      set_cache_header
      @title = "Google RS #{params[:name]}"
      erb :rs_example, locals: {
        head: :examples,
        name: params[:name],
        root: url("/")
      }
    end

    # Return source of a specific Google Rich Snippet example
    # @method get_rs_example
    # @overload get "/examples/google-rs/:file"
    # @param [String] file Name of the example to return
    get '/examples/google-rs/:file' do
      set_cache_header
      file_loc = params[:file]
      send_file File.join(APP_DIR, "google-rs/#{file_loc}"),
        type: (params[:file].end_with?(".jsonld") ? :jsonld : :html),
        charset: "utf-8"
    end

    # Return a specific Good Relations example
    # @method get_gr_example
    # @overload get "/examples/good-relations/:name/"
    # @param [String] name Name of the example to return
    get '/examples/good-relations/:name/' do
      set_cache_header
      @title = "Good Relations #{params[:name]}"
      erb :gr_example, locals: {
        head: :examples,
        name: params[:name],
        root: url("/")
      }
    end

    # Return source of a specific Good Relations example
    # @method get_gr_example
    # @overload get "/examples/good-relations/:file"
    # @param [String] file Name of the example to return
    get '/examples/good-relations/:file' do
      set_cache_header
      send_file File.join(APP_DIR, "good-relations/#{params[:file]}"),
        type: (params[:file].end_with?(".jsonld") ? :jsonld : :html),
        charset: "utf-8"
    end

    # Return a specific schema.org example
    # @method get_sc_example
    # @overload get "/examples/schema.org/:name/"
    # @param [String] name Name of the example to return
    get '/examples/schema.org/:name/' do
      set_cache_header
      @title = "Schema.org #{params[:name]}"
      @examples ||= JSON.parse(File.read(File.join(APP_DIR, "schema.org/examples.json")))
      
      # Find examples using this class
      examples = {}
      @examples.fetch(params[:name], {}).each do |ex_num, formats|
        examples[ex_num] = {}
        formats.each do |format, path|
          src = File.read(File.join(APP_DIR, path))
          examples[ex_num][format.to_sym] = {
            path: RDF::URI(request.url).join("../" + File.basename(path)),
            src: src
          }
        end
      end

      request.logger.debug "examples for #{@title}: #{examples.keys.inspect}"
      erb :schema_example, locals: {
        head: :examples,
        name: params[:name],
        examples: examples,
        root: url("/")
      }
    end

    # Return source of a specific schema.org example
    # @method get_sc_example
    # @overload get "/examples/good-relations/:file"
    # @param [String] file Name of the example to return
    get '/examples/schema.org/:file' do
      set_cache_header
      file = File.join(APP_DIR, "schema.org", params[:file])
      if File.exist?(file)
        send_file file,
          type: :html,
          charset: "utf-8"
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
      set_cache_header
      erb :snippets, locals: {
        root: url("/"),
      }
    end
    get '/snippets' do
      redirect '/snippets/'
    end

    get '/snippets/:name' do
      set_cache_header
      @title = params[:name]
      erb :snippet, locals: {
        name: params[:name],
        root: url("/")
      }
    end

    private

    include Parser

    # Handle GET/POST / returning JSON
    # @param {Hash} params
    # @option params [String] :base_uri
    #   Base URI for decoding markup, defaluts to `:url` if present
    # @option params [String] :content
    #   Markup specified inline
    # @option params [String] :datafile
    #   Location of uploaded file containing markup
    # @option params [Boolean] :debug
    #   Return verbose debug output
    # @option params [String] :format
    #   Format to use when parsing file
    # @option params [String] :url
    #   Location of resource containing markup
    # @option params [Boolean] :validate
    #   Perform strict validation of markup
    def linter(params)
      reader_opts = {
        headers:  {
          "User-Agent"    => "Structured-Data-Linter/#{RDF::Linter::VERSION}",
          "Cache-Control" => "no-cache"
        },
        verify_none: params["verify_ssl"] == "false",
        encoding: Encoding::UTF_8
      }
      reader_opts[:format] = params["format"].to_sym if params["format"]
      reader_opts[:base_uri] = params["url"].strip if params["url"]
      reader_opts[:tempfile] = params["file"][:tempfile] if params["file"]
      unless params["content"].to_s.empty?
        content = params["content"]
        content = content.encode(Encoding::UTF_8) unless content.encoding.to_s.include?("UTF")
        reader_opts[:content] = content
      end
      reader_opts[:debug] = @debug = [] if params["debug"] || settings.development?
      reader_opts[:matched_templates] = []
      reader_opts[:logger] = request.logger

      writer_opts = reader_opts.merge(standard_prefixes: true)

      root = url("/")
      request.logger.debug "params: #{params.inspect}"

      unless reader_opts[:base_uri].nil? || RDF::URI(reader_opts[:base_uri]).absolute?
        raise ArgumentError, "URL must be absolute: #{reader_opts[:base_uri]}"
      end

      # Parse and lint input yielding a graph
      graph, messages, reader = parse(reader_opts)
      raise "Graph not read" unless graph

      # Write in requested format
      writer = RDF::Writer.for(reader_opts.fetch(:output_format, :rdfa))

      writer_opts[:base_uri] ||= reader.base_uri if reader && reader.base_uri
      writer_opts[:debug] ||= [] if logger.level <= Logger::DEBUG
      request.logger.debug graph.dump(:ttl, writer_opts)

      result = snippet = nil
      if graph.size > 0
        # Move elements with class `snippet` to the front of the root element
        result = writer.buffer(writer_opts.merge(haml: RDF::Linter::TABULAR_HAML)) {|w| w << graph}
        result.gsub!(/--root--/, root)

        # Generate snippet
        snippet = begin
          RDF::Linter::Writer.buffer(writer_opts) {|w| w << graph}
        rescue
          request.logger.error "Snippet Writer returned error: #{$!.inspect}"
          raise
        end

        snippet.gsub!(/--root--/, root)
      end

      # Return snippet, serialized graph, lint messages, and debug information
      content_type :json
      {
        snippet: snippet,
        html: result,
        messages: messages.map {|k, v| v.map {|o, mm| Array(mm).map {|m| "#{k} #{o}: #{m}"}}}.flatten,
        statistics: {
          count: graph.size,
          reader: reader.class.name,
          templates: reader_opts[:matched_templates].uniq
        },
        debug: (writer_opts[:debug].join("\n") if writer_opts[:debug])
      }.to_json
    rescue RDF::ReaderError, ArgumentError => e
      request.logger.error "RDF::ReaderError: #{e.message}"
      request.logger.debug e.backtrace.join("\n")
      content_type :json
      status 400
      messages ||= {}
      messages[:error] ||= {}
      messages[:error]["RDF::ReaderError"] = [e.message]
      {
        messages: messages.map {|k, v| v.map {|o, mm| Array(mm).map {|m| "#{k} #{o}: #{m}"}}}.flatten,
        debug: (writer_opts[:debug].join("\n") if writer_opts[:debug])
      }.to_json
    rescue IOError => e
      request.logger.error "Failed to open #{reader_opts[:base_uri]}: #{e.message}"
      request.logger.debug e.backtrace.join("\n")
      content_type :json
      status 502
      messages ||= {}
      messages[:error] ||= {}
      messages[:error]["IOError"] = ["Failed to open #{reader_opts[:base_uri]}: #{e.message}"]
      {
        messages: messages.map {|k, v| v.map {|o, mm| Array(mm).map {|m| "#{k} #{o}: #{m}"}}}.flatten,
        debug: (writer_opts[:debug].join("\n") if writer_opts[:debug])
      }.to_json
    rescue
      raise unless settings.production?
      request.logger.error "#{$!.class}: #{$!.message}"
      content_type :json
      status 400
      messages ||= {}
      messages[:error] ||= {}
      messages[:error][$!.class] = [$!.message]
      {
        messages: messages.map {|k, v| v.map {|o, mm| Array(mm).map {|m| "#{k} #{o}: #{m}"}}}.flatten,
        debug: (writer_opts[:debug].join("\n") if writer_opts[:debug])
      }.to_json
    end

    # Should use Rack::Conneg, but helpers not loading properly
    #
    # @param [Symbol] ext (type)
    #   optional extension to override accept matching
    def respond_to(type = nil)
      wants = { '*/*' => Proc.new { raise TypeError, "No handler for #{request.accept.join(',')}" } }
      def wants.method_missing(ext, *args, &handler)
        type = ext == :other ? '*/*' : Rack::Mime::MIME_TYPES[".#{ext.to_s}"]
        self[type] = handler
      end

      yield wants

      pref = if type
        Rack::Mime::MIME_TYPES[".#{type.to_s}"]
      else
        supported_types = wants.keys.map {|ext| Rack::Mime::MIME_TYPES[".#{ext.to_s}"]}.compact
        request.preferred_type(*supported_types)
      end
      (wants[pref.to_s] || wants['*/*']).call
    end
  end
end
