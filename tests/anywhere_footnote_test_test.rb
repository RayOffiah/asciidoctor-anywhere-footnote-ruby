# frozen_string_literal: true

require 'asciidoctor'
require_relative '../lib/anywhere-footnote-extension'
require_relative '../lib/anywhere_footnote_processor'
require 'minitest/autorun'

class Anywhere_Footnote_Test < Minitest::Test
  def setup
    # Do nothing
  end

  def teardown
    # Do nothing
  end

  def test_basic_functionality

    input_document = <<~EOF

= Test document


++++
<link rel="stylesheet" href="anywhere-footnote.css"/>
++++

This is a test document.
It has two lines{empty}afnote:first-block[This is a footnote], the last of which will contain a footnote

afnote:first-block[]
    
EOF

    output_document = Asciidoctor.convert(input_document, backend: :html5, header_footer: false, safe: :safe, standalone: true)
    File.write("basic.html", output_document)

  end

  def test_for_two_footnotes


    input_document = <<~EOF

= Test document

++++
<link rel="stylesheet" href="anywhere-footnote.css"/>
++++

This is a test document.
It has two lines{empty}afnote:first-block[This is a footnote], the last of which will contain a footnote{empty}afnote:first-block[This a second footnote]. And we have another sentence before the block

afnote:first-block[]
    
EOF

    output_document = Asciidoctor.convert(input_document, backend: :html5, header_footer: false, safe: :safe, standalone: true)
    File.write("two-footnotes.html", output_document)

  end


  def test_for_markers


    input_document = <<~EOF

= Test document

++++
<link rel="stylesheet" href="anywhere-footnote.css"/>
++++

This is a test document.
It has two lines{empty}afnote:first-block[marker='*', refid='reference', reftext='This is a footnote'], 
the last of which will contain a footnote{empty}afnote:first-block[refid='reference']
And we have another sentence before the block

afnote:first-block[]
    
EOF

    output_document = Asciidoctor.convert(input_document, backend: :html5, header_footer: false, safe: :safe, standalone: true)
    File.write("markers.html", output_document)

  end

  def test_referencing_footnotes
    input_document = <<~EOF

= Test document

++++
<link rel="stylesheet" href="anywhere-footnote.css"/>
++++

This is a test document.
It has two lines{empty}afnote:first-block[refid='reference', reftext='This is a footnote'], 
the last of which will contain a footnote{empty}afnote:first-block[refid='reference']
And we have another sentence before the block

afnote:first-block[]

    EOF

    output_document = Asciidoctor.convert(input_document, backend: :html5, header_footer: false, safe: :safe, standalone: true)
    File.write("referencer.html", output_document)
  end

  def test_braces
    input_document = <<~EOF

= Test document

++++
<link rel="stylesheet" href="anywhere-footnote.css"/>
++++

This is a test document.
It has two lines{empty}afnote:first-block[marker='*', refid='reference', reftext='This is a footnote', lbrace='{', rbrace='}'],  
the last of which will contain a footnote{empty}afnote:first-block[refid='reference']
And we have another sentence before the block

afnote:first-block[]

    EOF

    output_document = Asciidoctor.convert(input_document, backend: :html5, header_footer: false, safe: :safe, standalone: true)
    File.write("braces.html", output_document)
  end

  def test_multiple_blocks

    input_document = <<~EOF

= Test document

:afnote-block-reset: false
:afnote-omit-separators: true
:afnote-format: alpha

++++
<link rel="stylesheet" href="anywhere-footnote.css"/>
++++

This is a test document.
It has two lines{empty}afnote:first-block[This is a footnote], the last of which will contain a footnote
            
But what is this? Yes, another set of footnotes in a different block{empty}afnote:second-block[This is a footnote for the second block]

== First block of footnotes
afnote:first-block[]
        
== Second block of footnotes
afnote:second-block[]

    EOF

    output_document = Asciidoctor.convert(input_document, backend: :html5, header_footer: false, safe: :safe, standalone: true)
    File.write("multiple-blocks.html", output_document)
  end
end
