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
