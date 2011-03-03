
module Webby::Helpers
  module UltraVioletHelper

    def uv_from_file(filename, opts = {})
      text = File.new(filename).read
      return if text.empty?

      defaults = ::Webby.site.uv
      lang = opts.getopt(:lang, defaults[:lang])
      line_numbers = opts.getopt(:line_numbers, defaults[:line_numbers])
      theme = opts.getopt(:theme, defaults[:theme])

      out = "<div class='UltraViolet'>\n"
      out << Uv.parse(text, "xhtml", lang, line_numbers, theme)
      out << "\n</div>"

      out
    end
  end
end
