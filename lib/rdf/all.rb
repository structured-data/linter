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
    ##
    # Only matched with :format => :all
    class Format < RDF::Format
      reader { RDF::All::Reader }
    end
    
    ##
    # Generic reader, detects appropriate readers and passes to each one
    class Reader < RDF::Reader
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
          @input.rewind

          RDF::Reader.each do |reader_class|
            if reader_class.detect(sample)
              #puts "detected #{reader_class.name}"
              begin
                reader_class.new(@input, @options) do |reader|
                  reader.each_statement do |statement|
                    block.call(statement)
                  end
                end
              rescue RDF::ReaderError
                # Ignore errors
              end
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
      sample.match(/<(\w+:)?(RDF)/)
    end
  end
  
  class RDFa::Reader
    ##
    # If the sample seems to be XML and contains an @about, @resource,
    # @profile, or @typeof attributes, presume that it is RDFa
    #
    # @param [String] sample
    # @return [Boolean]
    def self.detect(sample)
      sample.match(/<\w+/) &&
      sample.match(/<[^>]*(about|resource|profile|typeof)\s*="[^>]*>/m) &&
      !sample.match(/<(\w+:)?(RDF)/)
    end
  end
  
  class Microdata::Reader
    # If the sample seems to be XML and contains an @itemprop, @itemtype,
    # @itemscope, or @itemref attributes, presume that it is Mocridata
    #
    # @param [String] sample
    # @return [Boolean]
    def self.detect(sample)
      sample.match(/<\w+/) &&
      sample.match(/<[^>]*(itemprop|itemtype|itemref)[^>]*>/m)
    end
  end
  
  class N3::Reader
    # If the sample contains @base or @prefix
    #
    # @param [String] sample
    # @return [Boolean]
    def self.detect(sample)
      sample.match(/@(base|prefix)/) &&
      !::JSON::LD::Reader.detect(sample)
    end
  end
  
  class ::JSON::LD::Reader
    # If the sample contains @subject, @context, or @type
    #
    # @param [String] sample
    # @return [Boolean]
    def self.detect(sample)
      sample.match(/@(subject|context|type)/)
    end
  end
end # RDF
