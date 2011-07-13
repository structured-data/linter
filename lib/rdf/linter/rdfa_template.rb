# Default HAML templates used for generating output from the writer
require 'rdf/linter/vocab'

module RDF::Linter
  LINTER_HAML = {
    # Document
    # Locals: language, title, profile, prefix, base, subjects
    # Yield: subjects.each
    :doc => %q(
      %div{:id => "results-content", :about => base, :profile => profile, :prefix => prefix}
        - subjects.each do |subject|
          != yield(subject)
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
      - if element == :li
        %li{:about => resource, :typeof => typeof}
          - if typeof
            %span.type!= typeof
          %table.properties
            - predicates.each do |predicate|
              != yield(predicate)
      - elsif rel && typeof
        %td{:rel => rel}
          %div{:about => resource, :typeof => typeof}
            %span.type!= typeof
            %table.properties
              - predicates.each do |predicate|
                != yield(predicate)
      - elsif rel
        %td{:rel => rel, :resource => resource}
          %table.properties
            - predicates.each do |predicate|
              != yield(predicate)
      - else
        %div{:about => about, :typeof => typeof, :class => (typeof.nil? && 'notype')}
          - if typeof.nil?
            %h3
              Content from
              = about
          - if typeof
            %span.type!= typeof
          %table.properties
            - predicates.each do |predicate|
              != yield(predicate)
    ),

    # Output for single-valued properties
    # Locals: property, objects
    # Render as a leaf
    # Otherwise, render result
    :property_value => %q(
      %tr.property
        %td.label
          = get_predicate_name(predicate)
        - if res = yield(object)
          != res
        - elsif object.node?
          %td.base{:resource => get_curie(object), :rel => rel}= get_curie(object)
        - elsif object.uri?
          %td.base
            %a{:href => object.to_s, :rel => rel}= object.to_s
        - elsif object.datatype == RDF.XMLLiteral
          %td.base{:property => property, :lang => get_lang(object), :datatype => get_dt_curie(object)}<!= get_value(object)
        - else
          %td.base{:property => property, :content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
    ),

    # Output for multi-valued properties
    # Locals: property, rel, :objects
    :property_values =>  %q(
      %tr.property
        %td.label
          = get_predicate_name(predicate)
        %td{:rel => rel, :property => property}
          %ul
            - objects.each do |object|
              - if res = yield(object)
                != res
              - elsif object.node?
                %li.base{:resource => get_curie(object)}= get_curie(object)
              - elsif object.uri?
                %li.base
                  %a{:href => object.to_s}= object.to_s
              - elsif object.datatype == RDF.XMLLiteral
                %li.base{:lang => get_lang(object), :datatype => get_curie(object.datatype)}<!= get_value(object)
              - else
                %li.base{:content => get_content(object), :lang => get_lang(object), :datatype => get_dt_curie(object)}= escape_entities(get_value(object))
    ),
  }
end

Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), 'snippets/*.rb')).each { |s| require s }

