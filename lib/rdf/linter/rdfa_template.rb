# Default HAML templates used for generating output from the writer
# This format is based on Google Rich Snippets output
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

    # Output for top-level non-leaf resources
    #
    # Locals: subject, typeof, predicates, rel, element
    # Yield: predicates.each
    :subject => %q(
      - if typeof
        - # Use snippet format
        - title = yield(:title)
        - photo = yield(:photo)
        - body = yield(:body)
        - description = yield(:description)
        - other = yield(:other)
        %div{:class => "snippet-content", :about => about, :typeof => typeof}
          - if title
            %h3.r
              %a.fakelink
                != title
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
                      - if description
                        %br
                        != description
                      %br
                      %span.f
                        %cite!= base
            - else
              %div.s.primary_content
                %div.f
                  != body
                - if description
                  %br
                  != description
                %br
                %span.f
                  %cite!= base
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
        %span{:rel => rel}
          %span{:about => resource, :typeof => typeof}
            != yield(:nested)
          %span.other
            -#
              Content not used in snippet generation
              != yield(:other_nested)
      - else
        %span.other
          -#
            Content not used in snippet generation
          %div{:rel => rel}
            %div{:about => resource, :typeof => typeof}
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

