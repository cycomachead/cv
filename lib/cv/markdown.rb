# frozen_string_literal: true

require 'fileutils'

module CV
  # Renders the canonical CV Markdown document from YAML data + personal.bib.
  # The output is a single self-contained Markdown file with optional Jekyll
  # front matter, suitable for either local kramdown preview or dropping into
  # a Jekyll site.
  module Markdown
    DEFAULT_OUTPUT       = CV::BUILD_DIR.join('cv.md')
    EMBED_DEFAULT_OUTPUT = CV::BUILD_DIR.join('cv-embed.md')

    module_function

    def build(output: DEFAULT_OUTPUT, jekyll: true, page_header: true, data: nil, bib: nil)
      data ||= CV::Data.load
      bib  ||= CV::Bib.load
      renderer = CV::Renderer.new(format: :markdown)

      body = renderer.render('cv', data: data, bib: bib,
                                   locals: { jekyll_front_matter: jekyll,
                                             page_header:        page_header })
      FileUtils.mkdir_p(File.dirname(output))
      File.write(output, body)
      output
    end

    # Variant for the Jekyll site: keeps front matter, drops the in-page
    # name/title/contact/bio block. The deployed page already has its own
    # site-level page header, and the CV-specific download buttons + TOC
    # live in the sidebar include rather than the markdown.
    #
    # Referee contact details need no gate here: the Markdown output is public
    # either way, so cv.md.erb never emits them at all.
    def build_embed(output: EMBED_DEFAULT_OUTPUT, data: nil, bib: nil)
      build(output: output, jekyll: true, page_header: false, data: data, bib: bib)
    end
  end
end
