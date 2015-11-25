require 'rspec/matchers'

RSpec::Matchers.define :have_xpath do |xpath, value, trace|
  match do |actual|
    @doc = Nokogiri::XML.parse(actual)
    expect(@doc).to be_a(Nokogiri::XML::Document)
    expect(@doc.root).to be_a(Nokogiri::XML::Element)
    @namespaces = @doc.namespaces.merge("xhtml" => "http://www.w3.org/1999/xhtml", "xml" => "http://www.w3.org/XML/1998/namespace")
    case value
    when false
      expect(@doc.root.at_xpath(xpath, @namespaces)).to be_nil
    when true
      expect(@doc.root.at_xpath(xpath, @namespaces)).not_to be_nil
      true
    when Array
      expect(@doc.root.at_xpath(xpath, @namespaces).to_s.split(" ")).to include(*value)
    when Regexp
      expect(@doc.root.at_xpath(xpath, @namespaces).to_s).to match value
    when String
      expect(@doc.root.at_xpath(xpath, @namespaces).to_s).to eql value
    else
      false
    end
  end
  
  failure_message do |actual|
    msg = "expected that #{xpath.inspect} would be #{value.inspect} in:\n" + actual.to_s
    msg += "was: #{@doc.root.at_xpath(xpath, @namespaces)}" rescue @doc
    msg +=  "\nDebug:#{trace.join("\n")}" if trace
    msg
  end
  
  failure_message_when_negated do |actual|
    msg = "expected that #{xpath.inspect} would not be #{value.inspect} in:\n" + actual.to_s
    msg +=  "\nDebug:#{trace.join("\n")}" if trace
    msg
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