require 'rdf/turtle'

##
# Generate the schema.org example output template by reading
# in the type class/subClass heirarchy from schema.org/all.ttl
# and generating an entry for each class represented in an example.
#
# Link the definitions together heirarchically using class/subClass
# relationships.
module RDF::Linter
  class Schema
    attr_reader :classes
    attr_reader :thing

    def initialize
      graph = RDF::Graph.load("http://schema.rdfs.org/all.ttl")
      @classes = {'Thing' => {}}
      graph.query([:class, RDF::RDFS.subClassOf, :sub_class]) do |solution|
        s, p, o = solution.to_a.map {|r| r.to_s.sub("http://schema.org/", "")}
        @classes[s] = {:super_class => o}
      end
      
      # Create hierarchical order of classes
      @classes.each do |c, s|
        sc = s[:super_class]
        next unless @classes.has_key?(sc)
        @classes[sc][:sub_classes] ||= {}
        @classes[sc][:sub_classes][c] = @classes[c]
      end
      
      # Remember Thing
      @thing = @classes['Thing']
    end
    
    ##
    # Add an example to the class list
    #
    # @param [String] path to example file
    def add_example(path)
      markup_type = File.extname(path)[1..-1].to_sym
      example_number = if md = path.split('/').last.match(/^\w+-(\w+)\.\w+$/)
        md[1]
      else
        "Base"
      end
      t = path.split('/')[-2]
      t = "EducationalOrganization" if t == "EdducationalOrganization"
      if @classes.has_key?(t)
        puts "add example #{path} on class #{t}"
        @classes[t][:examples] ||= {}
        @classes[t][:examples][example_number] ||= {}
        @classes[t][:examples][example_number][markup_type] = path
      end
    end
    
    ##
    # Trim leaf classes having no examples until there
    # are no more leaves without examples
    def trim_classes
      deletions = 1
      while deletions > 0 do
        deletions = 0
        @classes.each do |cls, value|
          next unless value.fetch(:sub_classes, {}).empty? && !value.has_key?(:examples)
          deletions += 1
          @classes.delete(cls)
          sc = value[:super_class]
          next unless sc
          puts "trim class #{cls}, super-class #{sc}"
          @classes[sc][:sub_classes].delete(cls)
        end
      end
    end
    
    ##
    # Create examples partial
    #
    # @param[String] root base URL of service
    # @param[String] cls class name to render
    # @param[Integer] depth of rendering
    def create_partial(cls, depth)
      puts "create partial for #{cls} at depth #{depth}"

      output = %(<div class="example d#{depth}">\n)
      output += "  &nbsp;&nbsp;|&nbsp;&nbsp;" * depth
      if @classes[cls].has_key?(:examples)
        # Create link to class-specific page
        output += %(<a href="/examples/schema.org/#{cls}/" title="Show #{cls} markup examples">#{cls}</a>\n)
        # Output examples
        @classes[cls][:examples].keys.sort.each do |num|
          example = @classes[cls][:examples][num]
          output += %(\n<div class="ex">) + "  &nbsp;&nbsp;|&nbsp;&nbsp;" * depth
          output += %[&nbsp;&nbsp;#{num} (]
          output += [:rdfa, :jsonld, :microdata].map do |fmt|
            if example.has_key?(fmt)
              fmt_name = {:rdfa => "RDFa", :microdata => "microdata", :jsonld => "JSON-LD"}[fmt]
              sn_path = "<%=root%>/examples/schema.org/#{File.basename(example[fmt])}"
              %(<a href="/?url=#{sn_path}" title="Show #{cls} snippet in #{fmt_name}">#{fmt_name}</a>)
            end
          end.join(" ")
          output += ")"

          type = RDF::URI("http://schema.org/" + cls)
          unless RDF::Linter::LINTER_HAML.has_key?(type)
            output += %(<a href="#no_snip" title="snippets not currently generated for this type">*</a>)
          end
          output += "</div>\n"
        end
      else
        output += "#{cls}\n"
      end
      output += %(</div>\n)
      @classes[cls].fetch(:sub_classes, {}).keys.sort.each do |sc|
        output += create_partial(sc, depth + 1)
      end
      output
    end
  end
end