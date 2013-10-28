require 'nokogiri'

module RDF
  ##
  # **`RDF::All`** Attempts to read and parse all formats.
  #
  # Documentation
  # -------------
  #
  # * {RDF::All::Format}
  # * {RDF::All::Reader}
  # * {RDF::NTriples::Writer}
  #
  # @example Requiring the `RDF::All` module explicitly
  #   require 'rdf/all'
  module All
    class << self
      attr_accessor :debug
      def debug?; @debug; end
    end

    ##
    # Only matched with :format => :all
    class Format < RDF::Format
      reader { RDF::All::Reader }
    end
    
    ##
    # Generic reader, detects appropriate readers and passes to each one
    class Reader < RDF::Reader
      ##
      # Returns the base URI determined by this reader.
      #
      # @attr [RDF::URI]
      attr_reader :base_uri

      ##
      # Returns a hash of the number of statements parsed by each reader.
      #
      # @attr [Hash<Class, Integer>] statement_count
      attr :statement_count

      ##
      # Finds each appropriate reader and yields statements
      # from each reader found.
      #
      # Take a sample from the input and pass to each Reader which implements
      # a .detect class method
      #
      # @overload each_statement
      #   @yield  [statement]
      #     each statement
      #   @yieldparam  [RDF::Statement] statement
      #   @yieldreturn [void] ignored
      #   @return [void]
      #
      # @overload each_statement
      #   @return [Enumerator]
      #
      # @return [void]
      # @see    RDF::Enumerable#each_statement
      def each_statement(&block)
        if block_given?
          $logger ||= begin
            logger = Logger.new(STDOUT)  # In case we're not invoked from rack
            logger.level ::RDF::All.debug? ? Logger::DEBUG : Logger::INFO
            logger
          end
          @input.rewind
          sample = @input.read(1000).force_encoding(Encoding::UTF_8)
          if sample.match(%r(<html)i)
            # If it's HTML, parse it to improve detection
            @input.rewind
            @input = ::Nokogiri::HTML.parse(@input)
            sample = @input.to_html
            $logger.debug "HTML sample =  #{sample}"
          else
            @input.rewind
          end

          @statement_count = {}
          
          RDF::Reader.each do |reader_class|
            $logger.debug "check #{reader_class.name}"
            if reader_class.format.detect(sample)
              $logger.debug "detected #{reader_class.name}"
              begin
                @input.rewind if @input.respond_to?(:rewind)
                reader_class.new(@input, @options) do |reader|
                  reader.each_statement do |statement|
                    @statement_count[reader_class] ||= 0
                    @statement_count[reader_class] += 1
                    block.call(statement)
                  end
                  @base_uri ||= reader.base_uri unless reader.base_uri.to_s.empty?
                end
              rescue RDF::ReaderError
                # Ignore errors
              end
              $logger.info "parsed #{@statement_count[reader_class].to_i} triples from #{reader_class.name}"
            end
          end
        end
        enum_for(:each_statement)
      end

      ##
      # Iterates the given block for each RDF triple.
      #
      # If no block was given, returns an enumerator.
      #
      # Triples are yielded in the order that they are read from the input
      # stream.
      #
      # @overload each_triple
      #   @yield  [subject, predicate, object]
      #     each triple
      #   @yieldparam  [RDF::Resource] subject
      #   @yieldparam  [RDF::URI]      predicate
      #   @yieldparam  [RDF::Term]     object
      #   @yieldreturn [void] ignored
      #   @return [void]
      #
      # @overload each_triple
      #   @return [Enumerator]
      #
      # @return [void]
      # @see    RDF::Enumerable#each_triple
      def each_triple(&block)
        if block_given?
          each_statement do |statement|
            block.call(statement.to_triple)
          end
        end
        enum_for(:each_triple)
      end
    end
  end
end # RDF
