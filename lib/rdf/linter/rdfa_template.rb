# Default HAML templates used for generating output from the writer
# This format is based on Google Rich Snippets output

module RDF::Linter
  LINTER_HAML = {
    # Document
    # Locals: language, title, prefix, base, subjects, extracted
    # Yield: subjects.each
    :doc => %q(
      %div.results-content{:about => base, :prefix => prefix}
        - subjects.each do |subject|
          != yield(subject)
    ),

    # Output for top-level non-leaf resources
    #
    # Locals: subject, typeof, predicates, rel, element, inlist
    # Yield: predicates.each
    :subject => %q(
      - if typeof
        - # Use snippet format
        - title = yield(:title)
        - photo = yield(:photo)
        - body = yield(:body)
        - placeholder = "an <strong>actual</strong> search result <strong>may</strong> display other content <strong>relating</strong> to your search terms here."
        - description = yield(:description)
        - other = yield(:other)
        %div{:class => ("snippet-content" if title), :about => about, :typeof => typeof}
          - if title
            %h3.r
              %a.fakelink
                != title
            %div.s
              %div.f
                %cite!= base.to_s.gsub("https://", "").gsub("http://", "")
          - if body || description || photo
            - if !photo.to_s.empty?
              %div.s
                %table.ts
                  %tr
                    %td.left-image
                      %a.fakelink
                        != photo
                    %td.primary_content
                      %div.f
                        != body
                      %div
                        != placeholder
                      - if description
                        %br
                        != description
            - else
              %div.s.primary_content
                %div.f
                  != body
                %div
                  != placeholder
                - if description
                  %br
                  != description
          - if other
            %div.other
              %p="Content not used in snippet generation:"
              != other
      - else
        %div.other.notype{:about => about, :typeof => typeof}
          - predicates.each do |predicate|
            != yield(predicate)
    ),

    # :rel Used to create a condenced version of this snippet, when it's included in another.
    :rel => %(
      - if typeof
        %span{:property => rel, :resource => resource, :typeof => typeof}
          != yield(:nested)
        %span.other
          -#
            Content not used in snippet generation
            != yield(:other_nested)
      - else
        %span.other
          -#
            Content not used in snippet generation
          %div{:property => rel, :resource => resource}
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
        %link{:property => rel, :href => get_curie(object)}
    ),
  }

  TABULAR_HAML = {
    # Document
    # Locals: language, title, prefix, base, subjects, extracted
    # Yield: subjects.each
    :doc => %q(
      %div.extracted-content
        - subjects.each do |subject|
          != yield(subject)
    ),

    :subject => %q(
      - if element == :li
        %li
          %table.properties
            - if typeof
              %tr
                %td.label="rdf:type"
                %td!=typeof
            - predicates.each do |predicate|
              != yield(predicate)
      - else
        %div
          %table.properties
            -if subject.uri? || ref_count(subject) > 1
              %tr
                %td.label="@id"
                %td!="#{subject}(#{ref_count(subject)})"
            - if typeof
              %tr
                %td.label="rdf:type"
                %td!=typeof
            - predicates.each do |predicate|
              != yield(predicate)
    ),

    # Output for single-valued properties
    # Locals: property, rel, object
    # Yields: object
    # If nil is returned, render as a leaf
    # Otherwise, render result
    :property_value => %q(
      %tr.property
        %td.label
          = get_predicate_name(predicate)
        - if res = yield(object)
          %td!= res
        - elsif object.node?
          %td= get_curie(object)
        - elsif object.uri?
          %td
            %a{:href => object.to_s}= object.to_s
        - elsif object.datatype == RDF.XMLLiteral
          %td<!= get_value(object)
        - else
          %td{:lang => get_lang(object)}= escape_entities(get_value(object))
   ),

    # Output for multi-valued properties
    # Locals: property, rel, :objects
    # Yields: object for leaf resource rendering
    :property_values =>  %q(
      %tr.property
        %td.label
          = get_predicate_name(predicate)
        %td
          %ul
            - objects.each do |object|
              - if res = yield(object)
                != res
              - elsif object.node?
                %li= get_curie(object)
              - elsif object.uri?
                %li
                  %a{:href => object.to_s}= object.to_s
              - elsif object.datatype == RDF.XMLLiteral
                %li{:lang => get_lang(object)}<!= get_value(object)
              - else
                %li{:lang => get_lang(object)}= escape_entities(get_value(object))
    ),
  }

end

Dir.glob(File.join(File.expand_path(File.dirname(__FILE__)), 'snippets/*.rb')).each { |s| require s }

