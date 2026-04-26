# frozen_string_literal: true

require 'cgi'

module CV
  # Macros translate the small in-line conventions used in YAML/LaTeX source
  # into HTML or LaTeX output. Authors write source text using a few simple
  # markers (e.g. "Snap!", "[label](url)") and the macros engine converts them
  # to the appropriate format. This means YAML content can be authored once and
  # rendered for both targets without bespoke escaping.
  module Macros
    module_function

    # Stylized words. The HTML form wraps the "!" in <em>; the LaTeX form
    # mirrors the existing \snap / \snapcon macros from main.tex so the two
    # documents stay visually consistent.
    STYLIZED = {
      'Snap!Con'  => { html: 'Snap<em>!</em>Con',  latex: '\snapcon{}'   },
      'Snap!shot' => { html: 'Snap<em>!</em>shot', latex: '\snapshot{}'  },
      'Snap!'     => { html: 'Snap<em>!</em>',     latex: '\snap{}'      }
    }.freeze

    # Render an inline string to HTML.
    # Supported markers (kept intentionally small — this is not a markdown impl):
    #   Snap! / Snap!Con / Snap!shot     — stylized via STYLIZED
    #   [text](url)                       — link
    #   **bold** / *italic*               — emphasis
    #   bare URLs (http/https)            — auto-linked
    def to_html(str)
      return '' if str.nil?
      out = str.to_s.dup

      # Apply stylized words against a sentinel-protected string so we don't
      # mangle subsequent regex passes.
      placeholders = {}
      STYLIZED.each_with_index do |(word, repl), idx|
        token = "\x00ST#{idx}\x00"
        placeholders[token] = repl[:html]
        out.gsub!(word, token)
      end

      out = CGI.escapeHTML(out)

      # Markdown-ish links: [label](url)
      out.gsub!(/\[([^\]]+)\]\(([^)]+)\)/) do
        label, url = Regexp.last_match(1), Regexp.last_match(2)
        %(<a href="#{url}">#{label}</a>)
      end

      # Emphasis. Bold first so '**' is consumed before '*'.
      out.gsub!(/\*\*([^*]+)\*\*/, '<strong>\1</strong>')
      out.gsub!(/(?<!\*)\*([^*]+)\*(?!\*)/, '<em>\1</em>')

      # Auto-link bare URLs that weren't already inside an <a>. The lookahead
      # prevents double-linking a URL that already became part of a link above.
      out.gsub!(%r{(?<!["'>=])(https?://[^\s<]+[^\s<.,;:!?\)])}) do
        url = Regexp.last_match(1)
        %(<a href="#{url}">#{url}</a>)
      end

      # Restore stylized placeholders.
      placeholders.each { |token, html| out.gsub!(token, html) }

      out
    end

    # Render an inline string to LaTeX-safe content. We assume callers want
    # paragraph-style content; nothing fancy. We do NOT escape every special
    # character (this is a small project — LaTeX content is already LaTeX-ish
    # in the source files), but we do swap stylized words for their macros.
    def to_latex(str)
      return '' if str.nil?
      out = str.to_s.dup
      STYLIZED.each do |word, repl|
        out.gsub!(word, repl[:latex])
      end
      # Markdown-ish links → \href
      out.gsub!(/\[([^\]]+)\]\(([^)]+)\)/) do
        label, url = Regexp.last_match(1), Regexp.last_match(2)
        "\\href{#{url}}{#{label}}"
      end
      out.gsub!(/\*\*([^*]+)\*\*/, '\\textbf{\1}')
      out.gsub!(/(?<!\*)\*([^*]+)\*(?!\*)/, '\\textit{\1}')
      out
    end

    # Convenience: format a list of "Last, First" author strings in human form.
    # If `bold_self` is supplied and matches an entry, that entry is wrapped
    # in <strong>...</strong> for HTML emphasis.
    def authors_to_html(authors, bold_self: 'Ball, Michael')
      authors = Array(authors)
      authors.map do |a|
        rendered = to_html(a)
        a == bold_self ? "<strong>#{rendered}</strong>" : rendered
      end.join('; ')
    end
  end
end
