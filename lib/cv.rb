# frozen_string_literal: true

require 'pathname'

module CV
  ROOT = Pathname.new(File.expand_path('..', __dir__))
  DATA_DIR     = ROOT.join('data')
  TEMPLATE_DIR = ROOT.join('templates')
  BUILD_DIR    = ROOT.join('build')
  BIB_FILE     = ROOT.join('personal.bib')
  # Handcrafted moderncv sources *and* the PDFs latexmk builds from them.
  # See latex/README.md.
  LATEX_DIR    = ROOT.join('latex')

  autoload :Macros,   'cv/macros'
  autoload :Bib,      'cv/bib'
  autoload :Data,     'cv/data'
  autoload :Renderer, 'cv/renderer'
  autoload :Markdown, 'cv/markdown'
  autoload :Latex,    'cv/latex'
  autoload :Sidebar,  'cv/sidebar'
  autoload :Preview,  'cv/preview'
end
