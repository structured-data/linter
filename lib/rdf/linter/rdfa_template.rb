# Default HAML templates used for generating output from the writer
require 'rdf/linter/vocab'

module RDF::Linter
  LINTER_HAML = {
    # Document
    # Locals: language, title, profile, prefix, base, subjects, turtle
    # Yield: subjects.each
    :doc => %q(
      %div{:id => "results-content", :about => base, :profile => profile, :prefix => prefix}
        - subjects.each do |subject|
          != yield(subject)
      %div{:id => "results-turtle"}
        %h3
          Results in Turtle:
        %pre{:id => "results-turtle"}
          != turtle
    ),

    # Output for non-leaf resources
    # Note that @about may be omitted for Nodes that are not referenced
    #
    # If _rel_ and _resource_ are not nil, the tag will be written relative
    # to a previous subject. If _element_ is :li, the tag will be written
    # with <li> instead of <div>.
    #
    # Note that @rel and @resource can be used together, or @about and @typeof, but
    # not both.
    #
    # Locals: subject, typeof, predicates, rel, element
    # Yield: predicates.each
    :subject => %q(
      - if rel && typeof
        %div{:rel => rel}
          %div{:about => resource, :typeof => typeof}
            %span.type!= typeof
            - predicates.each do |predicate|
              != yield(predicate)
      - elsif rel
        %div{:rel => rel, :resource => resource}
          - predicates.each do |predicate|
            != yield(predicate)
      - else
        %div{:about => about, :typeof => typeof, :class => (typeof.nil? && 'notype')}
          - predicates.each do |predicate|
            != yield(predicate)
    ),

    # Output for single-valued properties
    # Locals: property, objects
    # Render as a leaf
    # Otherwise, render result
    :property_value => %q(
    - if res = yield(object)
      != res
    - elsif object.literal?
      %span{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
    - else
      %span{:rel => rel, :resource => get_curie(object)}
    ),
  }
end

Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), 'snippets/*.rb')).each { |s| require s }

