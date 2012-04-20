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
    def self.debug?; @debug; end
    def self.debug=(value); @debug = value; end

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
          @input.rewind
          sample = @input.read(1000)
          if sample.match(%r(<html)i)
            # If it's HTML, parse it to improve detection
            @input.rewind
            sample = @input = ::Nokogiri::HTML.parse(@input)
            puts "HTML sample =  #{sample.to_html}" if ::RDF::All::debug?
          else
            @input.rewind
          end

          @statement_count = {}
          
          RDF::Reader.each do |reader_class|
            puts "check #{reader_class.name}" if ::RDF::All.debug?
            if reader_class.detect(sample)
              puts "detected #{reader_class.name}" if ::RDF::All.debug?
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
              puts "parsed #{@statement_count[reader_class].to_i} triples from #{reader_class.name}" if ::RDF::All.debug?
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
  
  class Reader
    ##
    # Detect if this reader might be able to parse input represented
    # by `sample`.
    #
    # Sub-classes should override this to perform better heuristic detection,
    # for example, using regular expressions to see if the input sample contains
    # elements that might be parsable.
    #
    # Default detect method always returns false
    #
    # @param [String] sample
    # @return [Boolean]
    def self.detect(sample)
      false
    end
  end
  
  class RDFXML::Reader
    ##
    # If the sample seems to be XML and contains an <RDF> element,
    # presume that it is RDF/XML
    #
    # @param [String] sample
    # @return [Boolean]
    def self.detect(sample)
      sample.match(/<(\w+:)?(RDF)/) if sample.is_a?(String)
    end
  end
  
  class RDFa::Reader
    ##
    # If the sample seems to be HTML, presume that it is RDFa
    #
    # @param [String] sample
    # @return [Boolean]
    def self.detect(sample)
      if sample.is_a?(::Nokogiri::HTML::Document)
        %w(about resource prefix typeof property vocab).any? {|attr| sample.at_xpath("//@#{attr}")}
      else
        (sample.match(/<[^>]*(about|resource|prefix|typeof|property|vocab)\s*="[^>]*>/m) ||
         sample.match(/<[^>]*DOCTYPE\s+html[^>]*>.*xmlns:/im)
        ) && !sample.match(/<(\w+:)?(RDF)/)
      end
    end
  end
  
  class Microdata::Reader
    # If the sample seems to be HTML, presume that it is Mocridata
    #
    # @param [String] sample
    # @return [Boolean]
    def self.detect(sample)
      if sample.is_a?(::Nokogiri::HTML::Document)
        %w(itemprop itemtype itemref itemscope itemid).any? {|attr| sample.at_xpath("//@#{attr}")}
      else
        sample.match(/<[^>]*(itemprop|itemtype|itemref|itemscope|itemid)[^>]*>/m)
      end
    end
  end
  
  class N3::Reader
    # If the sample contains @base or @prefix
    #
    # @param [String] sample
    # @return [Boolean]
    def self.detect(sample)
      sample.match(/@(base|prefix)/) && !::JSON::LD::Reader.detect(sample) if sample.is_a?(String)
    end
  end
  
  class ::JSON::LD::Reader
    # If the sample contains @subject, @context, or @type
    #
    # @param [String] sample
    # @return [Boolean]
    def self.detect(sample)
      sample.match(/\{\s*"@(subject|context|type)"/m) if sample.is_a?(String)
    end
  end
end # RDF
