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
      it {should be_ok}
      its(:content_type) {should include("text/html")}

      context "body" do
        %w{
          /html
        }.each do |xpath|
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
          it {should be_ok}
          its(:content_type) {should include("text/html")}
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
        expect_any_instance_of(RDF::Linter::Application).to receive(:linter).
          with(hash_including({})).
          and_return("<div/>")
        post "/", "file" => Rack::Test::UploadedFile.new(File.expand_path("../test.html", __FILE__), "text/html"), path: "test.html"
        last_response
      }
      it {should be_ok}
      its(:content_type) {should include("text/html")}
    end

    context "Form content" do
      subject {
        expect_any_instance_of(RDF::Linter::Application).to receive(:linter).
          with(hash_including({})).
          and_return("<div/>")
        post "/", %({"content": "<html></html>"})
        last_response
      }
      it {should be_ok}
      its(:content_type) {should include("text/html")}
    end
  end

  describe "get /examples/" do
    subject {
      get "/examples/"
      last_response
    }
    it {should be_ok}
    its(:content_type) {should include("text/html")}

    context "body" do
      [
        %(/html),
        %(//section[@class="content"]/h2[contains(text(), "Google Rich Snippets examples")]),
        %(//section[@class="content"]/div/a[contains(text(), "Review")]),
        %(//section[@class="content"]/h2[contains(text(), "Google Rich Snippets examples")]/) +
          %(../div/a[@href="/examples/google-rs/Review/"]),
        %(//a[@href="/?url=http://example.org/examples/google-rs/review.rdfa.html"]),

        %(//section[@class="content"]/h2[contains(text(), "Schema.org examples")]),
        %(//section[@class="content"]/h2[contains(text(), "Schema.org examples")]/) +
          %(../div/a[contains(text(), "CreativeWork")]),
        %(//section[@class="content"]/div/a[@href="/examples/schema.org/CreativeWork/"]),
        %(//a[@href="/?url=http://example.org/examples/schema.org/eg-10-rdfa.html"]),

        %(//section[@class="content"]/h2[contains(text(), "Good Relations examples")]),
        %(//section[@class="content"]/h2[contains(text(), "Good Relations examples")]) +
          %(/../div/a[contains(text(), "company")]),
        %(//section[@class="content"]/h2[contains(text(), "Good Relations examples")]/) +
          %(../div/a[@href="/examples/good-relations/company/"]),
        %(//a[@href="/?url=http://example.org/examples/good-relations/company.rdfa.html"]),
      ].each do |xpath|
        it "has xpath #{xpath}" do
          expect(subject.body).to have_xpath(xpath, true)
        end
      end
    end
  end

  describe "get /examples/google-rs/:name/" do
    subject {
      get "/examples/google-rs/Review/"
      last_response
    }
    it {should be_ok}
    its(:content_type) {should include("text/html")}

    context "body" do
      [
        %(/html),
        %(//h2[contains(text(), "RDFa")]),
        %(//h2[contains(text(), "Microdata")]),
      ].each do |xpath|
        it "has xpath #{xpath}" do
          expect(subject.body).to have_xpath(xpath, true)
        end
      end
    end
  end

  describe "get /examples/google-rs/:file" do
    {
      "review.rdfa.html" => "text/html",
      "review.md.html" => "text/html",
    }.each do |file, content_type|
      context file do
        subject {
          get "/examples/google-rs/#{file}"
          last_response
        }
        it {should be_ok}
        its(:content_type) {should include(content_type)}
      end
    end
  end

  describe "get /examples/good-relations/:name/" do
    subject {
      get "/examples/good-relations/company/"
      last_response
    }
    it {should be_ok}
    its(:content_type) {should include("text/html")}

    context "body" do
      [
        %(/html),
        %(//h2[contains(text(), "RDFa")]),
      ].each do |xpath|
        it "has xpath #{xpath}" do
          expect(subject.body).to have_xpath(xpath, true)
        end
      end
    end
  end

  describe "get /examples/good-relations/:file" do
    {
      "company.rdfa.html" => "text/html",
    }.each do |file, content_type|
      context file do
        subject {
          get "/examples/good-relations/#{file}"
          last_response
        }
        it {should be_ok}
        its(:content_type) {should include(content_type)}
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
        it {should be_ok}
        its(:content_type) {should include("text/html")}

        context "body" do
          [
            %(/html),
            %(//h2[contains(text(), "RDFa")]),
            %(//h2[contains(text(), "microdata")]),
            %(//h2[contains(text(), "JSON-LD")]),
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
      "Role-PerformanceRole-257-jsonld.html" => "text/html",
    }.each do |file, content_type|
      context file do
        subject {
          get "/examples/schema.org/#{file}"
          last_response
        }
        it {should be_ok}
        its(:content_type) {should include(content_type)}
      end
    end
  end
end
