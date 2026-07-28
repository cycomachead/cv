# frozen_string_literal: true

require 'fileutils'

module CV
  # Renders a single-file LaTeX CV from data/*.yml + personal.bib using
  # templates/latex/cv.tex.erb. Output is build/cv.tex by default; compile
  # with `latexmk -lualatex build/cv.tex` (the moderncv setup needs lualatex
  # because of fontspec).
  #
  # The handcrafted latex/main.tex + latex/1-education.tex etc. remain the
  # source of truth for the printable PDF until you decide to switch over.
  # See latex/README.md for how that document set is wired together.
  module Latex
    DEFAULT_OUTPUT = CV::BUILD_DIR.join('cv.tex')

    module_function

    def build(output: DEFAULT_OUTPUT, data: nil, bib: nil)
      data ||= CV::Data.load
      bib  ||= CV::Bib.load
      tex = CV::Renderer.new(format: :latex)
                        .render('cv.tex', data: data, bib: bib)
      FileUtils.mkdir_p(File.dirname(output))
      File.write(output, tex)
      output
    end
  end
end
