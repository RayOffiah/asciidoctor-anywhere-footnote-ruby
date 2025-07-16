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
end
