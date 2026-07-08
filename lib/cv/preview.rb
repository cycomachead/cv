# frozen_string_literal: true

require 'fileutils'

module CV
  # Local-preview pipeline: take the rendered cv.md and convert it to a
  # standalone HTML file using kramdown (the same renderer Jekyll uses), then
  # wrap it in a minimal HTML shell that mirrors what the deployed Jekyll
  # site will look like — sidebar with download buttons + section TOC + dark
  # mode toggle, content column with the rendered CV body.
  module Preview
    DEFAULT_OUTPUT = CV::BUILD_DIR.join('cv.html')

    module_function

    def build(input: CV::Markdown::DEFAULT_OUTPUT, output: DEFAULT_OUTPUT,
              cv_pdf_url: CV::Sidebar::DEFAULT_CV_PDF_URL,
              resume_pdf_url: CV::Sidebar::DEFAULT_RESUME_PDF_URL)
      require 'kramdown'
      require 'kramdown-parser-gfm'

      md = File.read(input, encoding: 'UTF-8')
      md = md.sub(/\A---\n.*?\n---\n+/m, '') # strip Jekyll front matter

      html_body = ::Kramdown::Document.new(
        md,
        input: 'GFM', auto_ids: true,
        smart_quotes: %w[apos rsquo apos rsquo]
      ).to_html

      sidebar = CV::Sidebar.render(html_body: html_body,
                                   cv_pdf_url: cv_pdf_url,
                                   resume_pdf_url: resume_pdf_url)
      shell   = File.read(CV::TEMPLATE_DIR.join('markdown', 'preview.html.erb'),
                          encoding: 'UTF-8')
      css     = File.read(CV::TEMPLATE_DIR.join('markdown', 'preview.css'),
                          encoding: 'UTF-8')
      script  = File.read(CV::TEMPLATE_DIR.join('markdown', 'cv-theme.js'),
                          encoding: 'UTF-8')

      html = shell.sub('{{TITLE}}',   'Michael Ball — CV')
                  .sub('{{CSS}}',     css)
                  .sub('{{SIDEBAR}}', sidebar)
                  .sub('{{BODY}}',    html_body)
                  .sub('{{SCRIPT}}',  script)

      FileUtils.mkdir_p(File.dirname(output))
      File.write(output, html)
      output
    end
  end
end
