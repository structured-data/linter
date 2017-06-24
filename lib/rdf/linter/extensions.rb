require 'rdf'
require 'tsort'
require 'active_support/values/time_zone'

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

  # Resource properties
  #
  # Properties arranged as a hash with the predicate Term as index to an array of resources or literals
  #
  # Example:
  #     graph.load(':foo a :bar; rdfs:label "An example" .', "http://example.com/")
  #     graph.resources(URI.new("http://example.com/subject")) =>
  #     {
  #       "http://www.w3.org/1999/02/22-rdf-syntax-ns#type" => \[<http://example.com/#bar>\],
  #       "http://example.com/#label"                       => \["An example"\]
  #     }
  def properties(subject, recalc = false)
    @properties ||= {}
    @properties.delete(subject.to_s) if recalc
    @properties[subject.to_s] ||= begin
      hash = Hash.new
      self.query(subject: subject) do |statement|
        pred = statement.predicate.to_s

        hash[pred] ||= []
        hash[pred] << statement.object
      end
      hash
    end
  end
end

class RDF::Literal
  class Date
    def humanize(lang = :en)
      d = object.strftime("%A, %d %B %Y")
      if has_timezone?
        d += if self.tz == 'Z'
          " UTC"
        else
          " #{ActiveSupport::TimeZone[self.tz.to_s.to_i].tzinfo.strftime("%Z")}"
        end
      end
      d
    end
  end
  
  class Time
    def humanize(lang = :en)
      t = object.strftime("%r")
      if has_timezone?
        t += if self.tz == 'Z'
          " UTC"
        else
          " #{ActiveSupport::TimeZone[self.tz.to_s.to_i].tzinfo.strftime("%Z")}"
        end
      end
      t
    end
  end
  
  class DateTime
    def humanize(lang = :en)
      d = object.strftime("%r on %A, %d %B %Y")
      if has_timezone?
        zone = if self.tz == 'Z'
          "UTC"
        else
          ActiveSupport::TimeZone[self.tz.to_s.to_i].tzinfo.strftime("%Z")
        end
        d.sub!(" on ", " #{zone} on ")
      end
      d
    end
  end
end
