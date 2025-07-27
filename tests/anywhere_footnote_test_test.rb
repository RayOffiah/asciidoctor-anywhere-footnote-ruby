# frozen_string_literal: true

require 'asciidoctor'

require_relative '../lib/asciidoctor/anywhere_footnote_processor'
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

afnote::first-block[]
    
EOF

    output_document = Asciidoctor.convert(input_document, backend: :html5, header_footer: false, safe: :safe, standalone: true)
    File.write("basic.html", output_document)

    assert(output_document.include?(%q{class="paragraph afnote-hr-divider}))
    assert(output_document.include?(%q{#afnote-first-block-1-def}))
    assert(output_document.include?(%q{<a id="afnote-first-block-1-def"></a><a href="#afnote-first-block-1-ref" class="afnote-marker">1</a>}))

  end

  def test_for_two_footnotes


    input_document = <<~EOF

= Test document

++++
<link rel="stylesheet" href="anywhere-footnote.css"/>
++++

This is a test document.
It has two lines{empty}afnote:first-block[This is a footnote], the last of which will contain a footnote{empty}afnote:first-block[This a second footnote]. And we have another sentence before the block

afnote::first-block[]
    
EOF

    output_document = Asciidoctor.convert(input_document, backend: :html5, header_footer: false, safe: :safe, standalone: true)
    File.write("two-footnotes.html", output_document)

    assert(output_document.include?(%q{It has two lines<span class="afnote-marker"><a id="afnote-first-block-1-ref"></a><a href="#afnote-first-block-1-def">1</a></span>, the last of which will contain a footnote<span class="afnote-marker"><a id="afnote-first-block-2-ref"></a><a href="#afnote-first-block-2-def">2</a></span>. And we have another sentence before the block</p>}))
    assert(output_document.include?(%q{<a href="#afnote-first-block-1-ref" class="afnote-marker">1</a>}))
    assert(output_document.include?(%q{<a href="#afnote-first-block-2-ref" class="afnote-marker">2</a>}))

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

    assert(output_document.include?(%q{<span class="afnote-marker"><a id="afnote-first-block-reference-ref"></a><a href="#afnote-first-block-reference-def">*</a></span>}))
    assert(output_document.include?(%q{<span class="afnote-marker"><a href="#afnote-first-block-reference-def">*</a></span>}))
    assert(output_document.include?(%q{<a id="afnote-first-block-reference-def"></a><a href="#" class="afnote-marker">*</a>}""))
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

    assert(output_document.include?(%q{<dt class="hdlist1"><a id="afnote-first-block-reference-def"></a><a href="#" class="afnote-marker">1</a></dt>}))

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

    assert(output_document.include?(%q{It has two lines<span class="afnote-marker"><a id="afnote-first-block-reference-ref"></a><a href="#afnote-first-block-reference-def">{*}</a></span>}))
    assert(output_document.include?(%q{<a id="afnote-first-block-reference-def"></a><a href="#" class="afnote-marker">{*}</a>}))
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

    assert(output_document.include?(%q{<a href="#afnote-first-block-1-def">a</a>}))
    assert(output_document.include?(%q{<a id="afnote-second-block-2-ref"></a><a href="#afnote-second-block-2-def">b</a>}))
    assert(output_document.include?(%q{<span class="afnote-block"><a id="afnote-first-block"></a>}))
    assert(output_document.include?(%q{<span class="afnote-block"><a id="afnote-second-block"></a>}))
    assert(output_document.include?(%q{<dt class="hdlist1"><a id="afnote-first-block-1-def"></a><a href="#afnote-first-block-1-ref" class="afnote-marker">a</a></dt>}))
    assert(output_document.include?(%q{<dt class="hdlist1"><a id="afnote-second-block-2-def"></a><a href="#afnote-second-block-2-ref" class="afnote-marker">b</a></dt>}))

  end

  def test_tables
    input_document = <<~EOF

         
= Test document

++++
<link rel="stylesheet" href="anywhere-footnote.css"/>
++++

This is a test document for tables.


.Sample Table Title
[cols="1,2,2", options="header"]
|===
|ID |Name |Description

|1
|Product Aafnote:first-block[This is the first footnote]
|High-quality widget with advanced features{empty}afnote:first-block[This is the second]

|2
|Product B
|Budget-friendly solution for everyday use

|3
|Product C
|Premium option with extended warranty
|===

.Quarterly Sales Report 2025
[cols="1,2,1,1,1", options="header"]
|===
|Quarter |Product |Units Sold |Revenue ($) |Profit Margin (%)

|Q1
|Smartphone Xafnote:second-block[This is for the second block.]
|5,420
|$1,084,000
|32.5

|Q1
|Laptop Pro
|1,875
|$2,250,000
|28.7

|Q1
|Smart Watch
|3,650
|$729,000
|41.2

|Q2
|Smartphone X
|6,780
|$1,356,000afnote:second-block[Pricey!]
|33.8

|Q2
|Laptop Pro
|2,140
|$2,568,000
|29.4

|Q2
|Smart Watch
|4,290
|$858,000
|42.1

|Q3
|Smartphone X
|7,890
|$1,578,000
|34.2

|Q3
|Laptop Pro
|2,560
|$3,072,000
|30.1

|Q3
|Smart Watch
|5,130
|$1,026,000
|43.5
|===

== First block of footnotes
afnote:first-block[]
        
== Second block of footnotes
afnote::second-block[]


.Sample Product Comparison
[cols="1,1,1,1"]
|===
|Product |Price ($) |Rating (1-5) |Stock Status

|Premium Headphonesafnote:mid-block[Special offer!] |249.99 |4.7 |In Stock

|Wireless Speaker |129.95 |4.2 |Limited

4+|afnote:mid-block[omit-separator="true"]

|Smart Watch |199.50 |4.5 |In Stock

|Bluetooth Earbuds |89.99 |4.0 |Out of Stock
|===

    EOF


    output_document = Asciidoctor.convert(input_document, backend: :html5, header_footer: false, safe: :safe, standalone: true)
    File.write("tables.html", output_document)

    assert(output_document.include?(%q{<a id="afnote-first-block-1-ref"></a><a href="#afnote-first-block-1-def">1</a>}))
    assert(output_document.include?(%q{<span class="afnote-marker"><a id="afnote-mid-block-5-ref"></a><a href="#afnote-mid-block-5-def">5</a></span>}))
    assert(output_document.include?(%q{<dt class="hdlist1"><a id="afnote-mid-block-5-def"></a><a href="#afnote-mid-block-5-ref" class="afnote-marker">5</a></dt>}))
  end

end
