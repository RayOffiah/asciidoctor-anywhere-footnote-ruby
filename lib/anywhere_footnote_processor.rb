
require 'asciidoctor'
require 'ruby-enum'

class Format
  include Ruby::Enum

  define :ARABIC, 'arabic'
  define :ROMAN, 'roman'
  define :ALPHA, 'alpha'

end

class AnywhereFootnoteProcessor < Asciidoctor::Extensions::InlineMacroProcessor

  use_dsl

  named :afnote
  name_positional_attributes 'refid', 'reftext','marker', 'lbrace', 'rbrace', 'omit-separator'

  AFNOTE_FORMAT = 'afnote-format'

  def process(parent, target, attrs)

    document = parent.document
    if document.attr? AFNOTE_FORMAT
      afnote_format = Format.find(document.attr AFNOTE_FORMAT)
    else
      afnote_format = Format.ARABIC
    end

  end

end

