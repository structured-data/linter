require 'rdf'
require 'tsort'
require 'curb'

# Allow graph to be topologically sorted
class RDF::Graph
  include TSort
  
  alias_method :tsort_each_node, :each_subject
  
  ##
  # Reverse this, as we want reverse dependency order
  def tsort_each_child(node, &block)
    query(:object => node) do |statement|
      block.call(statement.subject)
    end
  end
end

class RDF::Literal
  ##
  # Returns a human-readable value for the interval
  def humanize(lang = :en)
    to_s
  end

  class Date
    def humanize(lang = :en)
      @object.strftime("%A, %d %B %Y %Z")
    end
  end
  
  class Time
    def humanize(lang = :en)
      @object.strftime("%r %Z").sub(/\+00:00/, "UTC")
    end
  end
  
  class DateTime
    def humanize(lang = :en)
      @object.strftime("%r %Z on %A, %d %B %Y").sub(/\+00:00/, "UTC")
    end
  end
end

module RDF::Util
  module File
    ##
    # Override to use Patron for http and https, Kernel.open otherwise.
    #
    # @param [String] filename_or_url to open
    # @param  [Hash{Symbol => Object}] options
    # @option options [Array, String] :headers
    #   HTTP Request headers.
    # @return [IO] File stream
    # @yield [IO] File stream
    def self.open_file(filename_or_url, options = {}, &block)
      case filename_or_url.to_s
      when /^file:/
        path = filename_or_url[5..-1]
        Kernel.open(path.to_s, &block)
      when /^http/
        io_obj = StringIO.new
        c = Curl::Easy.perform(filename_or_url) do |curl|
          curl.headers['Accept'] = 'text/turtle, application/rdf+xml;q=0.8, text/plain;q=0.4, */*;q=0.1'
          curl.headers['User-Agent'] = "Ruby Structured Data Linter/#{RDF::Linter::VERSION}"
          curl.on_body {|body| io_obj.write(body); body.length}
          curl.on_success {|easy, code| io_obj.instance_variable_set(:@status, code || 200)}
          curl.on_failure {|easy, code| io_obj.instance_variable_set(:@status, code || 500)}
        end
        io_obj.rewind
        def io_obj.content_type
          @content_type
        end
        def io_obj.status
          @status
        end
        if block_given?
          begin
            block.call(io_obj)
          ensure
            io_obj.close
          end
        else
          io_obj
        end
      else
        Kernel.open(filename_or_url.to_s, &block)
      end
    end
  end
end
