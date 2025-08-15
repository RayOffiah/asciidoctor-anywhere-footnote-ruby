# frozen_string_literal: true

require 'asciidoctor'
require 'asciidoctor-pdf'
require_relative '../lib/asciidoctor/anywhere_footnote_processor'
require 'minitest/autorun'

class Anywhere_Footnote_PDF_test < Minitest::Test
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

      afnote::first-block[]
          
    EOF

    File.write('input.adoc', input_document)

    Asciidoctor.convert_file(
      'input.adoc',
      backend: 'pdf',
      safe: :safe,
      standalone: true,
      to_file: 'output.pdf',
      theme_dir: 'themes',
      theme: 'anywhere-footnote',
      mkdirs: false
    )

  end

end
