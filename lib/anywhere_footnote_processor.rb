require 'asciidoctor'
require 'ruby-enum'
require 'string_pattern'
require 'roman-numerals'

class Format
  include Ruby::Enum

  define :ARABIC, 'arabic'
  define :ROMAN, 'roman'
  define :ALPHA, 'alpha'

end

OMIT_SEPARATOR = 'omit-separator'
$footnote_list = []

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

  def process(parent, target, attrs)

    document = parent.document
    if document.attr? AFNOTE_FORMAT
      afnote_format = Format.find(document.attr AFNOTE_FORMAT)
    else
      afnote_format = Format::ARABIC
    end

    footnote = AnywhereFootnote.new

    omit_separator = if attrs[OMIT_SEPARATOR] == 'true'
                       true
                     end

    if attrs.empty? or attrs.has_key? OMIT_SEPARATOR

      omit_separator = if attrs[OMIT_SEPARATOR] == 'true'
                         true
                       end

      return process_footnote_block(self, parent, target, omit_separator)


    end

    footnote.block_id = target

    # This means we have at least a single text parameter
    if attrs[1]
      footnote.text_parameter = attrs[1]
    elsif attrs.has_key? 'reftext'
      footnote.text_parameter = attrs['reftext']
    else
      footnote.text_parameter = ""
    end

    footnote.ref_id = if attrs.has_key? 'refid'
                        attrs['refid']
                      else
                        StringPattern.generate "8:NL"
                      end
    footnote.footnote_marker = if attrs.has_key? 'marker'
                                 attrs['marker']
                               end

    footnote.lbrace = if attrs.has_key? 'lbrace'
                        attrs['lbrace']
                      else
                        '&#91;'
                      end
    footnote.rbrace = if attrs.has_key? 'rbrace'
                        attrs['rbrace']
                      else
                        '&#93;'
                      end

    #  This odd bit of code is to ensure that we don't end up setting duplicate anchor ids
    #  for footnotes that reference other footnotes. In this case, the second footnote
    #  is assigned another random string, which means we won't be able to click to it
    # from the footnote block.

    add_footnote_reference(footnote, false)

    id_string = if $footnote_list.any? { |f| f.ref_id == footnote.ref_id }
                  ""
                else
                  "#{footnote.block_id}-#{footnote.ref_id}"
                end

    inline = create_footnote_reference(footnote, id_string)

    $footnote_list << footnote

    self.create_inline parent, :quoted, inline, :attributes => { 'role' => 'anywhere-footnote-marker' }

  end

  def add_footnote_reference(footnote, block_reset = false)

    # First, find the highest footnote number.
    # The easiest thing to do is
    #  count the number of footnotes in each block
    counter = number_of_footnotes_in_block(footnote.block_id, block_reset) + 1

    if footnote.ref_id and not footnote.text_parameter

      referenced_footnote = get_existing_footnote_marker($footnote_list, footnote.ref_id)
      # Add nil checking.
      footnote.footnote_marker = referenced_footnote&.footnote_marker
      footnote.ref_id = referenced_footnote&.ref_id

    else
      unless footnote.footnote_marker
        footnote.footnote_marker = formatted_number(counter)
      end
    end

  end

  def get_existing_footnote_marker(footnote_list, ref_id)

    footnote_list.find { |f| f.ref_id == ref_id }

  end

  def process_footnote_block(processor, parent, target, omit_separator)

    block_id = target

    grouped_footnotes = $footnote_list.group_by { |f| f.block_id }
    selected_block = grouped_footnotes[block_id]

    unless selected_block
      throw "No footnotes found for block #{block_id}"
    end

    separator_text = if omit_separator
                       ""
                     else
                       self.create_block(parent, :paragraph, "", {"role" => "anywhere-footnote-hr-divider"}).convert
                     end

    footnote_block_list = self.create_list(parent, :dlist, {"role" => "anywhere-footnote-horizontal"})

    selected_block.each do |footnote|
      term = "xref:#{footnote.block_id}-#{footnote.ref_id}-ref[#{footnote.lbrace}#{footnote.footnote_marker}#{footnote.rbrace}, role='anywhere-footnote-marker'][[#{footnote.block_id}-#{footnote.ref_id}-block]]"
      description ="#{footnote.text_parameter}"

      dlist_term = self.create_list_item(footnote_block_list, term)
      dlist_description = self.create_list_item(footnote_block_list, description)

      dlist_item = [[dlist_term], dlist_description]

      footnote_block_list.items << dlist_item

    end

    self.create_inline parent, :quoted, "#{separator_text}\n#{footnote_block_list.convert}", :attributes => { 'role' => 'anywhere-footnote-block' }


  end

  def create_footnote_reference(footnote, id_string)

    base_xref = "xref:#{footnote.block_id}-#{footnote.ref_id}-block[#{footnote.lbrace}#{footnote.footnote_marker}#{footnote.rbrace}]"
    id_string ? "[[#{id_string}-ref]]#{base_xref}" : base_xref

  end

  def number_of_footnotes_in_block(block_id, block_reset = false)

    if block_reset
      $footnote_list.find_all { |f| f.block_id == block_id and f.text_parameter }.size
    else
      $footnote_list.find_all { |f| f.block_id == block_id }.size
    end

  end

  def formatted_number(number, format = :ARABIC)
    case format
    when :ARABIC
      number.to_s
    when :ROMAN
      RomanNumerals.to_roman(number)
    when :ALPHA
      'a' + (number - 1).to_s
    else
      throw "Unknown format"
    end
  end

end



