require 'rdf'
require 'tsort'

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

module Sinatra::Helpers
  # Ensure that #send_file passes other options on to #content_type
  # Use the contents of the file at +path+ as the response body.
  def send_file(path, opts = {})
    if opts[:type] or not response['Content-Type']
      content_type opts[:type] || File.extname(path), opts.merge(:default => 'application/octet-stream')
    end

    disposition = opts[:disposition]
    filename    = opts[:filename]
    disposition = 'attachment' if disposition.nil? and filename
    filename    = path         if filename.nil?
    attachment(filename, disposition) if disposition

    last_modified opts[:last_modified] if opts[:last_modified]

    file      = Rack::File.new nil
    file.path = path
    result    = file.serving env
    result[1].each { |k,v| headers[k] ||= v }
    headers['Content-Length'] = result[1]['Content-Length']
    opts[:status] &&= Integer(opts[:status])
    halt opts[:status] || result[0], result[2]
  rescue Errno::ENOENT
    not_found
  end
end
