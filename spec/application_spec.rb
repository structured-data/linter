$:.unshift "."
require 'spec_helper'
require "rack/test"

describe RDF::Linter::Application do
  include Rack::Test::Methods

  def app
    RDF::Linter::Application.new
  end

  after(:each) do |example|
    if example.exception
      logdev = last_request.logger.instance_variable_get(:@logdev)
      dev = logdev.instance_variable_get(:@dev)
      dev.rewind
      puts dev.read
    end
  end

  describe "get /" do
    context "HTML" do
      subject {
        get "/"
        last_response
      }
      it {is_expected.to be_ok}
      its(:content_type) {is_expected.to include("text/html")}
      its(:body) {is_expected.to be_valid_html}

      context "body" do
        [
          %(/html/body[@class="linter"])
        ].each do |xpath|
          it "has xpath #{xpath}" do
            expect(subject.body).to have_xpath(xpath, true)
          end
        end
      end

      context "examples" do
        [
          '//span[@class="form-examples"]',
          '//span[@class="form-examples"]//a[@class="Review rdfa"]',
          '//span[@class="form-examples"]//a[@class="Review jsonld"]',
          '//span[@class="form-examples"]//a[@class="Review microdata"]',

          '//span[@class="form-examples"]//a[@class="Person rdfa"]',
          '//span[@class="form-examples"]//a[@class="Event jsonld"]',
          '//span[@class="form-examples"]//a[@class="Recipe microdata"]',
          '//span[@class="form-examples"]//a[@class="Product rdfa"]',
        ].each do |xpath|
          it "has xpath #{xpath}" do
            expect(subject.body).to have_xpath(xpath, true)
          end
        end
      end
    end

    context "JSON" do
      {
        "url" => {"url" => "http://example/"},
        "url and base_uri" => {"url" => "http://example/", "base_uri" => "http://foo/"},
        "format" => {"format" => "all"},
        "content" => {"content" => "foo"},
      }.each do |param, opts|
        context "with #{param}" do
          subject {
            expect_any_instance_of(RDF::Linter::Application).to receive(:linter).
              with(hash_including(opts)).
              and_return("<div/>")
            get "/", opts, "HTTP_ACCEPT" => "application/json"
            last_response
          }
          it {is_expected.to be_ok}
        end
      end
    end

    context "mal-formed" do
      it "requires url to be absolute" do
        get '/', {url: 'relative-foo', format: "ntriples"}, "HTTP_ACCEPT" => "application/json"
        expect(last_response).not_to be_ok
      end
    end
  end

  describe "post /" do
    context "File Upload" do
      subject {
        post "/", {
          "file" => Rack::Test::UploadedFile.new(File.expand_path("../test.html", __FILE__), "text/html"),
          path: "test.html"},
          "HTTP_ACCEPT" => "application/json"
        last_response
      }
      it {is_expected.to be_ok}
      its(:content_type) {is_expected.to include("application/json")}
    end

    context "Form content" do
      subject {
        post "/", %({"content": "<html></html>"})
        last_response
      }
      it {is_expected.to be_ok}
      its(:content_type) {is_expected.to include("application/json")}
    end
  end

  describe "get /examples/" do
    subject {
      get "/examples/"
      last_response
    }
    it {is_expected.to be_ok}
    its(:content_type) {is_expected.to include("text/html")}
    its(:body) {is_expected.to be_valid_html}

    context "body" do
      [
        %(/html),
        %(/html/body[@class="linter"]),
        %(//section[@class="content"]),

        %(//section[@class="content"]/h2[contains(text(), "Schema.org examples")]),
        %(//section[@class="content"]/h2[contains(text(), "Schema.org examples")]/) +
          %(../div/a[contains(text(), "CreativeWork")]),
        %(//section[@class="content"]/div/a[@href="/examples/schema.org/CreativeWork/"]),
      ].each do |xpath|
        it "has xpath #{xpath}" do
          expect(subject.body).to have_xpath(xpath, true)
        end
      end
    end
  end

  describe "get /examples/schema.org/:name/" do
    %w(
      CreativeWork Article AudioObject Movie Event Rating AggregateRating GeoCoordinates
      Person Place Product
    ).each do |name|
      context name do
        subject {
          get "/examples/schema.org/#{name}/"
          last_response
        }
        it {is_expected.to be_ok}
        its(:content_type) {is_expected.to include("text/html")}
        its(:body) {is_expected.to be_valid_html}

        context "body" do
          [
            %(/html),
            %(//h3[contains(text(), "RDFa")]),
            %(//h3[contains(text(), "microdata")]),
            %(//h3[contains(text(), "JSON-LD")]),
          ].each do |xpath|
            it "has xpath #{xpath}" do
              expect(subject.body).to have_xpath(xpath, true)
            end
          end
        end
      end
    end
  end

  describe "get /examples/schema.org/:file" do
    {
      "eg-0173-rdfa.html" => "text/html",
    }.each do |file, content_type|
      context file do
        subject {
          get "/examples/schema.org/#{file}"
          last_response
        }
        it {is_expected.to be_ok}
        its(:content_type) {is_expected.to include(content_type)}
      end
    end
  end

  describe "#linter" do
    context :format do
    end

    context :base_uri do
    end
  end
end
