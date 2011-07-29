module RDF::Linter
  module Vocab
    class V < RDF::Vocabulary("http://rdf.data-vocabulary.org/#"); end
    class VMD < RDF::Vocabulary("http://data-vocabulary.org/"); end
    class GR < RDF::Vocabulary("http://purl.org/goodrelations/v1#"); end
    class VCARD < RDF::Vocabulary("http://www.w3.org/2006/vcard/ns#"); end
  end
end