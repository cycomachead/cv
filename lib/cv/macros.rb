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

    # Stylized words. The Markdown form uses *…* (italic) so kramdown renders
    # it as <em>!</em>; the HTML form is the same after conversion. The LaTeX
    # form mirrors the existing \snap / \snapcon macros in latex/main.tex so both
    # documents stay visually consistent.
    # The Markdown form embeds raw <em> HTML rather than `*!*` because
    # kramdown won't re-emphasize an asterisk pair already inside an italic
    # span (so a thesis title like _Lambda: ...Snap!_ would otherwise leave
    # the `*!*` literal). Inline HTML inside Markdown is fine for both
    # kramdown and Jekyll.
    STYLIZED = {
      'Snap!Con'  => { md: 'Snap<em>!</em>Con',  html: 'Snap<em>!</em>Con',  latex: '\snapcon{}'  },
      'Snap!shot' => { md: 'Snap<em>!</em>shot', html: 'Snap<em>!</em>shot', latex: '\snapshot{}' },
      'Snap!'     => { md: 'Snap<em>!</em>',     html: 'Snap<em>!</em>',     latex: '\snap{}'     }
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

    # Render an inline string as Markdown. Markdown is the canonical authoring
    # format: links, bold, and italic in the YAML are already markdown-shaped,
    # so this pass mainly substitutes stylized words. The output is fed to
    # kramdown (or a Jekyll site) for the final HTML.
    def to_md(str)
      return '' if str.nil?
      out = str.to_s.dup
      STYLIZED.each { |word, repl| out.gsub!(word, repl[:md]) }
      out
    end

    # LaTeX special characters that need escaping when found in plain prose.
    # We deliberately do NOT escape `\`, `{`, `}` because the macros engine
    # itself emits `\href{}`, `\snap{}`, `\textbf{}`, etc. after this pass —
    # those backslashes and braces must reach the output unchanged. Source
    # YAML doesn't contain literal backslashes or braces in practice.
    LATEX_ESCAPES = { '&' => '\\&', '%' => '\\%', '$' => '\\$',
                      '#' => '\\#', '_' => '\\_' }.freeze

    # Render an inline string to LaTeX-safe content. Steps:
    #   1. escape LaTeX special chars in the user prose
    #   2. swap stylized words (`Snap!` → `\snap{}`)
    #   3. expand markdown links / bold / italic to LaTeX equivalents
    def to_latex(str)
      return '' if str.nil?
      out = str.to_s.dup
      out.gsub!(/[&%$#_]/, LATEX_ESCAPES)
      STYLIZED.each { |word, repl| out.gsub!(word, repl[:latex]) }
      out.gsub!(/\[([^\]]+)\]\(([^)]+)\)/) do
        label, url = Regexp.last_match(1), Regexp.last_match(2)
        # The url has already been through the escaper, undo `\#` and `\&`
        # for inside \href{} where they're harmful.
        clean_url = url.gsub('\\#', '#').gsub('\\&', '&').gsub('\\_', '_')
        "\\href{#{clean_url}}{#{label}}"
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

    def authors_to_md(authors, bold_self: 'Ball, Michael')
      Array(authors).map do |a|
        rendered = to_md(a)
        a == bold_self ? "**#{rendered}**" : rendered
      end.join('; ')
    end
  end
end
