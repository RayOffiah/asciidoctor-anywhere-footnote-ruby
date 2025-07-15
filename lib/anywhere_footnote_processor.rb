require 'asciidoctor'
require 'ruby-enum'

class Format
  include Ruby::Enum

  define :ARABIC, 'arabic'
  define :ROMAN, 'roman'
  define :ALPHA, 'alpha'

end

OMIT_SEPARATOR = 'omit-separator'

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
  name_positional_attributes 'refid', 'reftext', 'marker', 'lbrace', 'rbrace', 'omit-separator'

  AFNOTE_FORMAT = 'afnote-format'



  def process(parent, target, attrs)

    footnote_list = []

    document = parent.document
    if document.attr? AFNOTE_FORMAT
      afnote_format = Format.find(document.attr AFNOTE_FORMAT)
    else
      afnote_format = Format.ARABIC
    end

    footnote = AnywhereFootnote.new

    omit_separator = if attrs[OMIT_SEPARATOR] == 'true'
                       true
                     end

    process_footnote_block(self, parent, target, omit_separator)

    footnote.block_id = target

    # This means we have at least a single text parameter
    if attrs.positional_attributes.size > 0
      footnote.text_parameter = attrs.positional_attributes[0]
    elsif attrs.has_key? 'reftext'
      footnote.text_parameter = attrs['reftext']
    else
      footnote.text_parameter = ""
    end

    footnote.ref_id = if attrs.has_key? 'refid'
                        attrs['refid']
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

    id_string = if footnote_list.any? {|f| f.ref_id == footnote.ref_id}
                  ""
                else
                  "#{footnote.block_id}-#{footnote.ref_id}"
                end

    inline = create_footnote_reference(footnote, id_string)

  end


  def process_footnote_block(processor, parent, target, omit_separator)

  end

  def create_footnote_reference(footnote, id_string)

    base_xref = "xref:#{footnote.block_id}-#{footnote.ref_id}-block[#{footnote.lbrace}#{footnote.footnote_marker}#{footnote.rbrace}]"
    return id_string ? "[[#{id_string}-ref]]#{base_xref}" : base_xref
  end

end



