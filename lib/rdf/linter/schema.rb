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
      @classes = {}
      @examples = {}

      RDF::Vocab::SCHEMA.each do |vocab_term|
        term = vocab_term.to_s[18..-1]
        @classes[term] = {super_class: vocab_term.subClassOf.map {|c| c.to_s[18..-1]}.first}
      end
      
      # Create hierarchical order of classes
      @classes.each do |c, s|
        sc = s[:super_class]
        next unless @classes.has_key?(sc)
        @classes[sc][:sub_classes] ||= []
        @classes[sc][:sub_classes] << c
      end
      
      # Remember Thing
      add_path('Thing', nil)
      @thing = @classes['Thing']
    end

    ##
    # Add class path to class
    def add_path(cls, super_class)
      if super_class
        @classes[cls][:path] = Array(@classes[super_class][:path]) + [super_class].compact
      else
        @classes[cls][:path] = []
      end
      (@classes[cls][:sub_classes] ||= []).each do |sub_class|
        add_path(sub_class, cls)
      end
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
        when :pre, :microdata, :rdfa, :jsonld
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

      # Create example index
      File.open(APP_DIR + "/schema.org/examples.json", "w") do |f|
        examples = @classes.keys.inject({}) {|memo, k|
          memo.merge(k => @classes[k] || {})
        }
        f.write(examples.to_json(JSON::LD::JSON_STATE))
      end

      # Create partial for example index
      File.open(APP_DIR + "/lib/rdf/linter/views/_schema_examples.erb", "w") do |f|
        f.puts("<!-- This file is created automaticaly by rake schema_examples -->")
        f.write(create_partial("Thing", []))
      end
    end

    ##
    # Add an example to the class list
    #
    # @param [String] types
    #   schema type of example, may be multiple separated by commas
    # @param [String] example the body of the example
    # @param [Integer] ex_num
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
    # Create class index partial
    #
    # @param[String] root base URL of service
    # @param[String] cls class name to render
    # @param[Integer] class path to this class.
    def create_partial(cls, path)
      puts "create partial for #{cls} at depth #{path.length}"

      output = %(<div class="example d#{path.length}">\n)
      output += "  &nbsp;&nbsp;|&nbsp;&nbsp;" * path.length

      # Create link to class-specific page
      output += %(<a href="/examples/schema.org/#{cls}/" title="Show #{cls}">#{cls}</a></div>\n)
      @classes[cls].fetch(:sub_classes, []).sort.uniq.each do |sc|
        output += create_partial(sc, path + [cls])
      end
      output
    end
  end
end