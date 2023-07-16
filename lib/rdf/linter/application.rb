require 'sinatra'
require 'sinatra/rdf'
require 'sprockets'
require 'sinatra/sprockets-helpers'
require 'uglifier'
require 'sass'
require 'erubis'

module RDF::Linter
  class Application < Sinatra::Base

    # Assets
    register Sinatra::Sprockets::Helpers
    set :sprockets, Sprockets::Environment.new(root)
    set :assets_prefix, '/assets'
    set :digest_assets, true

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

      # Assets
      # Setup Sprockets
      sprockets.append_path File.join(root, 'assets', 'css')
      sprockets.append_path File.join(root, 'assets', 'js')
      sprockets.js_compressor  = :uglify
      sprockets.css_compressor = :scss

      # Configure Sprockets::Helpers (if necessary)
      Sprockets::Helpers.configure do |config|
        config.environment = sprockets
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

    # get assets
    get "/assets/*" do
      env["PATH_INFO"].sub!("/assets", "")
      settings.sprockets.call(env)
    end

    # Get "/" either returns the main linter page or linted markup
    #
    # @!parse
    #   def get_linter; end
    # @see {#linter}
    get '/' do
      respond_to do |wants|
        wants.other { erb :linter, locals: {head: :linter, root: url("/")} }
        wants.json { linter params }
      end
    end

    # POST "/" returns linted markup as JSON
    #
    # @!parse
    #   def post_linter; end
    # @see {#linter}
    post '/' do
      payload = params
      payload = JSON.parse(request.body.read) unless params['file']
      linter payload
    end

    # Return about page
    # @!parse
    #   def get_about; end
    get '/about/' do
      @title = "About the Linter"
      set_cache_header
      erb :about
    end
    get '/about' do
      redirect '/about/'
    end

    # Return markup examples
    # @!parse
    #   def get_examples; end
    get '/examples/' do
      @title = "Markup Examples"
      set_cache_header
      erb :examples, locals: {root: url("/")}
    end
    get '/examples' do
      redirect '/examples/'
    end

    # Return a specific schema.org example
    # @param [String] name Name of the example to return
    # @!parse
    #   def get_sc_example(name); end
    get '/examples/schema.org/:name/' do
      set_cache_header
      @title = "Schema.org #{params[:name]}"
      @examples ||= JSON.parse(File.read(File.join(APP_DIR, "schema.org/examples.json")))
      
      # Find examples using this class
      examples = {}
      cls = @examples.fetch(params[:name], {})
      clsex = cls.fetch('examples', {})
      Array(clsex).each do |ex_num, formats|
        examples[ex_num] = {}
        formats.each do |format, path|
          src = File.read(File.join(APP_DIR, path))
          examples[ex_num][format.to_sym] = {
            path: RDF::URI(request.url).join("../" + File.basename(path)),
            src: src
          }
        end

        # Create strucure for this example
        struct_fmt = (formats.keys - [:pre]).last
        struct_src = File.read(File.join(APP_DIR, formats[struct_fmt]))
        graph = RDF::OrderedRepo.new << RDF::RDFa::Reader.new(struct_src)
        examples[ex_num][:struct] = {
          src: RDF::Linter::Writer.buffer(haml: RDF::Linter::TABULAR_HAML) {|w| w << graph}
        }
      end

      request.logger.debug "examples for #{@title}: #{examples.keys.inspect}"
      term = RDF::Vocab::SCHEMA[params[:name]]
      erb :schema_example, locals: {
        head: :examples,
        name: params[:name],
        label: term.label,
        comment: term.comment,
        examples: examples,
        root: url("/")
      }
    end

    # Robots
    # @param [String] file Name of the example to return
    # @!parse
    #   def get_sc_example(file); end
    get '/robots.txt' do
      set_cache_header
      file = File.join(APP_DIR, "robots.txt")
      if File.exist?(file)
        send_file file,
          type: :text,
          charset: "utf-8"
      else
        status 401
        body "Could not find schema example #{params[:file]}"
      end
    end

    # Return source of a specific schema.org example
    # @param [String] file Name of the example to return
    # @!parse
    #   def get_sc_example(file); end
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
    # @!parse
    #   def get_snippets; end
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

    # @param [String] name Name of the snippet to return
    # @!parse
    #   def get_snippets(name); end
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
      graph, messages, reader = parse(**reader_opts)
      raise "Graph not read" unless graph

      # Write in requested format
      writer = RDF::Writer.for(reader_opts.fetch(:output_format, :rdfa))

      writer_opts[:base_uri] ||= reader.base_uri if reader && reader.base_uri
      writer_opts[:debug] ||= [] if logger.level <= Logger::DEBUG
      request.logger.debug graph.dump(:ttl, **writer_opts)

      result = snippet = nil
      if graph.size > 0
        # Move elements with class `snippet` to the front of the root element
        result = writer.buffer(**writer_opts.merge(haml: RDF::Linter::TABULAR_HAML)) {|w| w << graph}
        result.gsub!(/--root--/, root)

        # Generate snippet
        snippet = begin
          RDF::Linter::Writer.buffer(**writer_opts) {|w| w << graph}
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
    # @param [Symbol] type (nil)
    #   optional extension to override accept matching
    def respond_to(type = nil)
      wants = { '*/*' => Proc.new { raise TypeError, "No handler for #{request.accept.join(',')}" } }

      wants.instance_exec do
        def method_missing(ext, *args, &handler)
          type = ext == :other ? '*/*' : Rack::Mime::MIME_TYPES[".#{ext.to_s}"]
          self[type] = handler
        end
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
