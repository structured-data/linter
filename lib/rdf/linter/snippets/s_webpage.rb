# data-vocabulary `Person` snippet:
module RDF::Linter
  LINTER_HAML.merge!({
    RDF::URI("http://schema.org/WebPage") => {
      :identifier => "schema:WebPage",
      :skip => true,
      :priority => 1,
    }
  })
end