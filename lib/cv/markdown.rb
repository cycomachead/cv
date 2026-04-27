# frozen_string_literal: true

require 'fileutils'

module CV
  # Renders the canonical CV Markdown document from YAML data + personal.bib.
  # The output is a single self-contained Markdown file with optional Jekyll
  # front matter, suitable for either local kramdown preview or dropping into
  # a Jekyll site.
  module Markdown
    DEFAULT_OUTPUT = CV::BUILD_DIR.join('cv.md')

    module_function

    def build(output: DEFAULT_OUTPUT, jekyll: true, data: nil, bib: nil)
      data ||= CV::Data.load
      bib  ||= CV::Bib.load
      renderer = CV::Renderer.new(format: :markdown)

      body = renderer.render('cv', data: data, bib: bib,
                                   locals: { jekyll_front_matter: jekyll })
      FileUtils.mkdir_p(File.dirname(output))
      File.write(output, body)
      output
    end
  end
end
