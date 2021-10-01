require 'rspec/matchers'

RSpec::Matchers.define :have_xpath do |path, value, trace|
  match do |actual|
    root = Nokogiri::HTML5(actual, max_parse_errors: 1000)
    return false unless root
    namespaces = root.namespaces.inject({}) {|memo, (k,v)| memo[k.to_s.sub(/xmlns:?/, '')] = v; memo}.
      merge("xhtml" => "http://www.w3.org/1999/xhtml", "xml" => "http://www.w3.org/XML/1998/namespace")
    @result = root.at_xpath(path, namespaces) rescue false
    case value
    when false
      @result.nil?
    when true
      !@result.nil?
    when Array
      @result.to_s.split(" ").include?(*value)
    when Regexp
      @result.to_s =~ value
    else
      @result.to_s == value
    end
  end
  
  failure_message do |actual|
    msg = "expected that #{path.inspect}\nwould be: #{value.inspect}"
    msg += "\n     was: #{@result}"
    msg += "\nsource:" + actual
    msg +=  "\nDebug:#{logger}"
    msg
  end

  failure_message_when_negated do |actual|
    msg = "expected that #{path.inspect}\nwould not be #{value.inspect}"
    msg += "\nsource:" + actual
    msg +=  "\nDebug:#{logger}"
    msg
  end
end

RSpec::Matchers.define :be_valid_html do
  match do |actual|
    root = Nokogiri::HTML5(actual, max_parse_errors: 1000)
    @errors = Array(root && root.errors.map(&:to_s))
    @errors.empty?
  end
  
  failure_message do |actual|
    "expected no errors, was #{@errors.join("\n")}"
  end
end

RSpec::Matchers.define :have_errors do |errors|
  match do |actual|
    actual = actual[1] if actual.is_a?(Array) # Messages in second element of array
    return false unless actual.keys == errors.keys
    actual.each do |area_key, area_values|
      return false unless errors.has_key?(area_key)
      return false unless area_values.length == errors[area_key].length
      errors[area_key].each do |term, values|
        return false unless area_values.has_key?(term)
        values.each do |v|
          case v
          when Regexp then v.match(Array(area_values[term]).join("\n"))
          else Array(area_values[term]).any? {|vv| v == vv}
          end
        end
      end
    end
    true
  end

  failure_message do |actual|
    "expected errors to match #{errors.to_json(JSON::LD::JSON_STATE)}\nwas #{actual.to_json(JSON::LD::JSON_STATE)}"
  end

  failure_message_when_negated do |actual|
    "expected errors not to match #{errors.to_json(JSON::LD::JSON_STATE)}"
  end
end