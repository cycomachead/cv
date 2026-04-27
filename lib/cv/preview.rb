# frozen_string_literal: true

require 'fileutils'

module CV
  # Local-preview pipeline: take the rendered cv.md and convert it to a
  # standalone HTML file using kramdown (the same renderer Jekyll uses), then
  # wrap it in a minimal HTML shell with preview CSS so you can open the file
  # in a browser without running Jekyll.
  module Preview
    DEFAULT_OUTPUT = CV::BUILD_DIR.join('cv.html')

    module_function

    def build(input: CV::Markdown::DEFAULT_OUTPUT, output: DEFAULT_OUTPUT)
      require 'kramdown'

      md = File.read(input, encoding: 'UTF-8')
      # Strip Jekyll front matter (kramdown chokes on it; Jekyll consumes it
      # at deploy time).
      md = md.sub(/\A---\n.*?\n---\n+/m, '')

      html_body = ::Kramdown::Document.new(md, input: 'GFM', auto_ids: true,
                                               smart_quotes: %w[apos rsquo apos rsquo])
                                      .to_html
      shell = File.read(CV::TEMPLATE_DIR.join('markdown', 'preview.html.erb'),
                        encoding: 'UTF-8')
      title = 'Michael Ball — CV'
      css   = File.read(CV::TEMPLATE_DIR.join('markdown', 'preview.css'),
                        encoding: 'UTF-8')

      html = shell.sub('{{TITLE}}', title)
                  .sub('{{CSS}}',   css)
                  .sub('{{BODY}}',  html_body)

      FileUtils.mkdir_p(File.dirname(output))
      File.write(output, html)
      output
    end
  end
end
