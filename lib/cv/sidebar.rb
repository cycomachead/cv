# frozen_string_literal: true

require 'erb'
require 'fileutils'

module CV
  # Build the sidebar HTML fragment that wraps the rendered CV. Used by:
  #   - CV::Preview (inlined into the standalone preview cv.html)
  #   - CV::Sidebar.build (writes build/cv-sidebar.html for the Jekyll deploy
  #     to include verbatim alongside the rendered Markdown body)
  #
  # The fragment contains: the download buttons (CV + 1-page resume), the
  # section TOC built from the rendered <h2>/<h3> ids, and the dark/light
  # theme toggle.
  module Sidebar
    DEFAULT_OUTPUT = CV::BUILD_DIR.join('cv-sidebar.html')
    TEMPLATE       = CV::TEMPLATE_DIR.join('markdown', 'sidebar.html.erb')

    DEFAULT_CV_PDF_URL     = 'cv.pdf'
    DEFAULT_RESUME_PDF_URL = 'resume.pdf'

    module_function

    # Render the sidebar fragment as a string.
    def render(html_body:, cv_pdf_url: DEFAULT_CV_PDF_URL,
               resume_pdf_url: DEFAULT_RESUME_PDF_URL)
      toc_html = build_toc(html_body)
      template = ERB.new(File.read(TEMPLATE, encoding: 'UTF-8'), trim_mode: '-')
      template.filename = TEMPLATE.to_s

      ctx = SidebarContext.new(
        cv_pdf_url:     cv_pdf_url,
        resume_pdf_url: resume_pdf_url,
        toc_html:       toc_html
      )
      template.result(ctx.get_binding)
    end

    # Write the sidebar fragment to disk for the Jekyll site to include.
    # The fragment is self-contained HTML — drop it into a Jekyll
    # `_includes/cv-sidebar.html` and it works as long as the page also
    # loads cv.css and cv-theme.js.
    def build(output: DEFAULT_OUTPUT, html_body: nil,
              cv_pdf_url: DEFAULT_CV_PDF_URL,
              resume_pdf_url: DEFAULT_RESUME_PDF_URL)
      html_body ||= read_rendered_body
      fragment = render(html_body: html_body,
                        cv_pdf_url: cv_pdf_url,
                        resume_pdf_url: resume_pdf_url)
      FileUtils.mkdir_p(File.dirname(output))
      File.write(output, fragment)
      output
    end

    # Extract the rendered <h2 id="…">Title</h2> (and h3) blocks from the
    # CV body and build a nested <ol>. We keep this naive because the input
    # is the output of our own template — no need for a full HTML parser.
    def build_toc(html_body)
      nav = +"    <ol>\n"
      open_h2 = open_h3 = false
      close_h2 = lambda do
        nav << "        </ol>\n" if open_h3
        # Indent the </li> only when it follows a nested list; otherwise it
        # closes the <a> line directly (no stray whitespace inside the item).
        nav << (open_h3 ? "      </li>\n" : "</li>\n") if open_h2
      end
      html_body.scan(%r{<h([23])\s+id="([^"]+)"[^>]*>(.*?)</h\1>}m).each do |level, id, label|
        text = label.gsub(/<[^>]+>/, '').strip
        if level == '2'
          close_h2.call
          nav << %(      <li><a href="##{id}">#{text}</a>)
          open_h2 = true
          open_h3 = false
        else
          unless open_h3
            nav << "\n        <ol>\n"
            open_h3 = true
          end
          nav << %(          <li><a href="##{id}">#{text}</a></li>\n)
        end
      end
      close_h2.call
      nav << "    </ol>\n"
      nav
    end

    # Tiny ERB context to expose the locals as methods.
    class SidebarContext
      def initialize(cv_pdf_url:, resume_pdf_url:, toc_html:)
        @cv_pdf_url     = cv_pdf_url
        @resume_pdf_url = resume_pdf_url
        @toc_html       = toc_html
      end
      attr_reader :cv_pdf_url, :resume_pdf_url, :toc_html
      def get_binding; binding; end
    end

    private_class_method def self.read_rendered_body
      require 'kramdown'
      require 'kramdown-parser-gfm'
      md = File.read(CV::Markdown::DEFAULT_OUTPUT, encoding: 'UTF-8')
      md = md.sub(/\A---\n.*?\n---\n+/m, '')
      ::Kramdown::Document.new(
        md,
        input: 'GFM', auto_ids: true
      ).to_html
    end
  end
end
