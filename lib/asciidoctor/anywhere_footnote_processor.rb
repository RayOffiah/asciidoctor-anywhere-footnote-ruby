require 'asciidoctor'
require 'ruby-enum'
require 'roman-numerals'



Asciidoctor::Extensions.register do

  $footnote_list = []

  inline_macro AnywhereFootnoteProcessor

end

class Format
  include Ruby::Enum

  define :ARABIC, 'arabic'
  define :ROMAN, 'roman'
  define :ALPHA, 'alpha'

end


class AnywhereFootnote
  attr_accessor :block_id, :ref_id, :text_parameter, :footnote_marker, :lbrace, :rbrace

  def initialize

    @block_id = ""
    @ref_id = ""
    @text_parameter = ""
    @footnote_marker = ""
    @lbrace = ""
    @rbrace = ""
  end
end

class AnywhereFootnoteProcessor < Asciidoctor::Extensions::InlineMacroProcessor

  use_dsl

  named :afnote

  AFNOTE_FORMAT = 'afnote-format'
  AFNOTE_BLOCK_RESET = 'afnote-block-reset'
  AFNOTE_OMIT_SEPARATORS ="afnote-omit-separators"
  OMIT_SEPARATOR = 'omit-separator'

  AFNOTE_ID_PREFIX = 'afnote-id-prefix'
  AFNOTE_CSS_PREFIX = 'afnote-css-prefix'

  AFNOTE_ID_DEFAULT_PREFIX = 'afnote-'
  AFNOTE_CSS_DEFAULT_PREFIX = 'afnote-'

  $afnote_id_prefix = AFNOTE_ID_DEFAULT_PREFIX
  $afnote_css_prefix = AFNOTE_CSS_DEFAULT_PREFIX

  def initialize(backend, document)
    super
    @name = 'afnote'
    @document = document

  end


  def process(parent, target, attrs)

    document = parent.document

    afnote_format = Format.key(document.attr(AFNOTE_FORMAT) || 'arabic')

    omit_separators_page_wide = document.attr? AFNOTE_OMIT_SEPARATORS, "true"

    $afnote_id_prefix = document.attr(AFNOTE_ID_PREFIX) || AFNOTE_ID_DEFAULT_PREFIX
    $afnote_css_prefix = document.attr(AFNOTE_CSS_PREFIX) || AFNOTE_CSS_DEFAULT_PREFIX

    footnote = AnywhereFootnote.new

    if target[0] == ':' or   attrs.empty? or attrs.has_key? OMIT_SEPARATOR

      omit_separator = attrs[OMIT_SEPARATOR] == 'true'

      block_id = target[0] == ':' ? target[1..-1] : target
      return process_footnote_block(parent, block_id, (omit_separator or omit_separators_page_wide))


    end

    block_reset = document.attr? AFNOTE_BLOCK_RESET, "true"


    footnote.block_id = target

    # This means we have at least a single text parameter
    footnote.text_parameter = attrs[1] || attrs['reftext'] || ""

    footnote.ref_id = attrs['refid'] || (number_of_footnotes_in_block(footnote.block_id, false) + 1).to_s

    footnote.footnote_marker = attrs['marker'] if attrs.has_key? 'marker'

    footnote.lbrace = attrs['lbrace'] || ''
    footnote.rbrace = attrs['rbrace'] || ''
    
    add_footnote_reference(footnote, block_reset, afnote_format)

    #  This odd bit of code is to ensure that we don't end up setting duplicate anchor ids
    #  for footnotes that reference other footnotes. In this case, the second footnote
    #  is assigned another random string, which means we won't be able to click to it
    # from the footnote block.

    id_string = if $footnote_list.any? { |f| f.ref_id == footnote.ref_id }
                  ""
                else
                  "#{$afnote_id_prefix}#{footnote.block_id}-#{footnote.ref_id}"
                end

    inline = create_footnote_reference(footnote, id_string)

    $footnote_list << footnote

    self.create_inline parent, :quoted, inline, :attributes => { 'role' => "#{$afnote_css_prefix}marker" }

  end

  def add_footnote_reference(footnote, block_reset = false, format = :ARABIC)

    # First, find the highest footnote number.
    # The easiest thing to do is
    #  count the number of footnotes in each block
    counter = number_of_footnotes_in_block(footnote.block_id, block_reset) + 1

    if footnote.ref_id and  footnote.text_parameter.empty?

      referenced_footnote = get_existing_footnote_marker($footnote_list, footnote.ref_id)
      # Add nil checking.
      footnote.footnote_marker = referenced_footnote&.footnote_marker
      footnote.ref_id = referenced_footnote&.ref_id

    else
      if footnote.footnote_marker.empty?
        footnote.footnote_marker = formatted_number(counter, format)
      end
    end

  end

  def get_existing_footnote_marker(footnote_list, ref_id)

    footnote_list.find { |f| f.ref_id == ref_id and not f.text_parameter.empty?}

  end

  def process_footnote_block(parent, target, omit_separator)

    block_id = target

    grouped_footnotes = $footnote_list.group_by { |f| f.block_id }
    selected_block = grouped_footnotes[block_id]

    unless selected_block
      throw "No footnotes found for block #{block_id}"
    end

    # Add an ID marker


    separator_text = if omit_separator
                       ""
                     else
                       self.create_block(parent, :paragraph, "", {"role" => "#{$afnote_css_prefix}hr-divider"}).convert
                     end

    footnote_block_list = self.create_list(parent, :dlist, {"role" => "#{$afnote_css_prefix}horizontal"})

    selected_block.each do |footnote|

      unless footnote.text_parameter.empty?

        # Some footnotes in the list are pointers to other footnotes.
        # If you have duplicate markers, then you will not be able to
        # point back to the original footnote. (Which one would you point back to?)
        # Instead, just use a fake reference when the block is rendered.

        xref_text = $footnote_list.count { |f| f.ref_id == footnote.ref_id } <= 1 ? "xref:#{$afnote_id_prefix}#{footnote.block_id}-#{footnote.ref_id}-ref" : "xref:#"

        term = "[[#{$afnote_id_prefix}#{footnote.block_id}-#{footnote.ref_id}-def]]#{xref_text}[#{footnote.lbrace}#{footnote.footnote_marker}#{footnote.rbrace}, role=\"#{$afnote_css_prefix}marker\"]"

        description = "#{footnote.text_parameter}"

        dlist_term = self.create_list_item(footnote_block_list, term)
        dlist_description = self.create_list_item(footnote_block_list, description)

        dlist_item = [[dlist_term], dlist_description]

        footnote_block_list.items << dlist_item
      end

    end

    self.create_inline parent, :quoted, "#{separator_text}\n#{footnote_block_list.convert}"


  end

  def create_footnote_reference(footnote, id_string)

    base_xref = "xref:#{$afnote_id_prefix}#{footnote.block_id}-#{footnote.ref_id}-def[#{footnote.lbrace}#{footnote.footnote_marker}#{footnote.rbrace}]"

    (not id_string.empty?) ? "[[#{id_string}-ref]]#{base_xref}" : base_xref

  end

  def number_of_footnotes_in_block(block_id, block_reset = false)

    if block_reset
      $footnote_list.find_all { |f| f.block_id == block_id and not f.text_parameter.empty? }.size
    else
      $footnote_list.find_all { |f| not f.text_parameter.empty? }.size
    end

  end

  def formatted_number(number, format = :ARABIC)
    case format
    when :ARABIC
      number.to_s
    when :ROMAN
      RomanNumerals.to_roman(number).downcase
    when :ALPHA
      number_to_letter(number)
    else
      throw "Unknown format"
    end
  end

  def number_to_letter(num)
    (num + 96).chr
  end

end



