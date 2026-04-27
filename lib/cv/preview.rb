# frozen_string_literal: true

require 'fileutils'

module CV
  # Local-preview pipeline: take the rendered cv.md and convert it to a
  # standalone HTML file using kramdown (the same renderer Jekyll uses), then
  # wrap it in a minimal HTML shell with a sidebar table of contents and the
  # preview CSS so you can open the file in a browser without running Jekyll.
  module Preview
    DEFAULT_OUTPUT = CV::BUILD_DIR.join('cv.html')

    module_function

    def build(input: CV::Markdown::DEFAULT_OUTPUT, output: DEFAULT_OUTPUT)
      require 'kramdown'
      require 'kramdown-parser-gfm'

      md = File.read(input, encoding: 'UTF-8')
      md = md.sub(/\A---\n.*?\n---\n+/m, '') # strip Jekyll front matter

      html_body = ::Kramdown::Document.new(
        md,
        input: 'GFM', auto_ids: true,
        smart_quotes: %w[apos rsquo apos rsquo]
      ).to_html

      sidebar = build_sidebar(html_body)
      shell   = File.read(CV::TEMPLATE_DIR.join('markdown', 'preview.html.erb'),
                          encoding: 'UTF-8')
      css     = File.read(CV::TEMPLATE_DIR.join('markdown', 'preview.css'),
                          encoding: 'UTF-8')

      html = shell.sub('{{TITLE}}',   'Michael Ball — CV')
                  .sub('{{CSS}}',     css)
                  .sub('{{SIDEBAR}}', sidebar)
                  .sub('{{BODY}}',    html_body)

      FileUtils.mkdir_p(File.dirname(output))
      File.write(output, html)
      output
    end

    # Extract the rendered <h2 id="…">Title</h2> (and h3) blocks and build a
    # nested sidebar nav. We keep this naive because the input is the output
    # of our own template — no need for a full HTML parser.
    def build_sidebar(html_body)
      nav = +'<nav class="toc" aria-label="Section navigation">' "\n  <ol>\n"
      open_h2 = open_h3 = false
      html_body.scan(%r{<h([23])\s+id="([^"]+)"[^>]*>(.*?)</h\1>}m).each do |level, id, label|
        text = label.gsub(/<[^>]+>/, '').strip
        if level == '2'
          nav << "    </ol>\n" if open_h3
          nav << "  </li>\n"   if open_h2
          nav << %(  <li><a href="##{id}">#{text}</a>)
          open_h2 = true
          open_h3 = false
        else
          unless open_h3
            nav << "\n    <ol>\n"
            open_h3 = true
          end
          nav << %(      <li><a href="##{id}">#{text}</a></li>\n)
        end
      end
      nav << "    </ol>\n" if open_h3
      nav << "  </li>\n"   if open_h2
      nav << "  </ol>\n</nav>\n"
      nav
    end
  end
end
