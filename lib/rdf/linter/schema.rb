require 'rdf/turtle'
require 'rdf/linter/rdfa_template'
require 'strscan'

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
      @classes = {'Thing' => {}}
      @examples = {}

      RDF::Vocab::SCHEMA.each do |vocab_term|
        term = vocab_term.to_s[18..-1]
        @classes[term] = {super_class: vocab_term.subClassOf.map {|c| c.to_s[18..-1]}.first}
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
    # Load examples from a text file, generate partials and type mapping.
    #
    # @param [String, #read] file
    def load_examples(file)
      s = StringScanner.new(file.respond_to?(:read) ? file.read : File.read(file))
      types = nil
      body = nil
      format = nil
      number = 0
      while !s.eos?
        # Scan each format until TYPES is found again, or EOF
        body = s.scan_until(/^(TYPES|PRE-MARKUP|MICRODATA|RDFA|JSON|JSONLD):/)
        if body.nil?
          body = s.rest
          s.terminate
        end

        # Trim body
        body = body[0..-(s.matched.to_s.length+1)].gsub("\r", '').strip + "\n"
        case format
        when :microdata, :rdfa, :jsonld
          add_example(types, body, number, format) unless types.include?("FakeEntryNeeded")
        end

        case s.matched
        when "TYPES:"
          types = s.scan_until(/$/).strip
          number += 1 unless types.include?("FakeEntryNeeded")
          format = :types
        when "PRE-MARKUP:"  then format = :pre
        when "MICRODATA:"   then format = :microdata
        when "RDFA:"        then format = :rdfa
        when "JSON:"        then format = :jsonld
        when "JSONLD:"      then format = :jsonld
        end
      end

      trim_classes

      # Create example index
      File.open(APP_DIR + "/schema.org/examples.json", "w") do |f|
        examples = @classes.keys.inject({}) {|memo, k|
          memo[k] = @classes[k][:examples] if @classes[k].has_key?(:examples); memo
        }
        f.write(examples.to_json(JSON::LD::JSON_STATE))
      end

      # Create partial for example index
      File.open(APP_DIR + "/lib/rdf/linter/views/_schema_examples.erb", "w") do |f|
        f.puts("<!-- This file is created automaticaly by rake schema_examples -->")
        f.write(create_partial("Thing", 0))
      end
    end

    ##
    # Add an example to the class list
    #
    # @param [String] types
    #   schema type of example, may be multiple separated by commas
    # @param [String] example the body of the example
    # @param [Integer] number
    #   This example number, used to create appropriate grouping
    # @param [Symbol] format :microdata, :rdfa, or :jsonld
    def add_example(types, example, ex_num, format)
      # Skip example if it is JSON only
      return if example =~ /This example is JSON only/m
      name = nil
      if types.start_with?('#')
        # In some cases, a more specific name is used.
        name, types = types.split(/\s+/, 2)
        name = name[1..-1]  # Remove initial '#'
      end
      types = types.split(/,\s*/)
      name ||= "#{types.join('-')}-#{ex_num}"

      # Write example out for reading later
      path = "schema.org/#{name}-#{format}.html"
      File.open(File.expand_path("../../../../#{path}", __FILE__), "w") {|f| f.write(example)}

      types.each do |t|
        next unless @classes.has_key?(t)
        
        @classes[t][:examples] ||= {}
        @classes[t][:examples][name] ||= {}
        @classes[t][:examples][name][format] = path
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
          @classes[sc][:sub_classes].delete(cls) if @classes.fetch(sc, {})[:sub_classes]
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
        @classes[cls][:examples].keys.sort.each do |name|
          example = @classes[cls][:examples][name]
          output += %(\n<div class="ex">) + "  &nbsp;&nbsp;|&nbsp;&nbsp;" * depth
          output += %[&nbsp;&nbsp;#{name} (]
          output += [:rdfa, :jsonld, :microdata].map do |fmt|
            if example.has_key?(fmt)
              fmt_name = {:rdfa => "RDFa", :microdata => "microdata", :jsonld => "JSON-LD"}[fmt]
              sn_path = "<%=root%>examples/schema.org/#{File.basename(example[fmt])}"
              %(<a href="/?url=#{sn_path}" title="Show #{cls} snippet in #{fmt_name}">#{fmt_name}</a>)
            end
          end.join(" ")
          output += ")"

          type = RDF::URI("http://schema.org/" + cls)
          unless RDF::Linter::LINTER_HAML.has_key?(RDF::URI(type))
            output += %(<a href="#no_snip" title="snippets not optimized for this type">*</a>)
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