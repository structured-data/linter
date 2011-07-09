require 'rspec/matchers'

RSpec::Matchers.define :have_xpath do |xpath, value|
  match do |actual|
    @doc = Nokogiri::XML.parse(actual)
    @doc.should be_a(Nokogiri::XML::Document)
    @doc.root.should be_a(Nokogiri::XML::Element)
    @namespaces = @doc.namespaces.merge("xhtml" => "http://www.w3.org/1999/xhtml", "xml" => "http://www.w3.org/XML/1998/namespace")
    case value
    when false
      @doc.root.at_xpath(xpath, @namespaces).should be_nil
    when true
      @doc.root.at_xpath(xpath, @namespaces).should_not be_nil
      true
    when Array
      @doc.root.at_xpath(xpath, @namespaces).to_s.split(" ").should include(*value)
    when Regexp
      @doc.root.at_xpath(xpath, @namespaces).to_s.should =~ value
    when String
      @doc.root.at_xpath(xpath, @namespaces).to_s.should == value
    else
      false
    end
  end
  
  failure_message_for_should do |actual|
    msg = "expected that #{xpath.inspect} would be #{value.inspect} in:\n" + actual.to_s
    msg += "was: #{@doc.root.at_xpath(xpath, @namespaces)}"
  end
end
