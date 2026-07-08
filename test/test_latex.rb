# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'

class LatexBuildTest < Minitest::Test
  def test_scaffolds_full_cv_tex
    Dir.mktmpdir do |dir|
      out = CV::Latex.build(output: File.join(dir, 'cv.tex'))
      assert File.file?(out)
      tex = File.read(out, encoding: 'UTF-8')

      assert_includes tex, '\documentclass[12pt, letterpaper, unicode]{moderncv}'
      assert_includes tex, '\begin{document}'
      assert_includes tex, '\end{document}'

      # Sections we expect to find.
      %w[Education Positions Awards Service References].each do |s|
        assert_includes tex, "\\section{#{s}}"
      end

      # Personal data is interpolated.
      assert_includes tex, '\name{Michael}{Ball}'
      assert_includes tex, '\email{ball@berkeley.edu}'
    end
  end

  def test_escapes_special_chars_in_body
    Dir.mktmpdir do |dir|
      tex = File.read(CV::Latex.build(output: File.join(dir, 'cv.tex')),
                      encoding: 'UTF-8')
      # & must be escaped (e.g. "EECS \& Data Science")
      assert_includes tex, 'EECS \&'
      # $50,000 grants must escape the dollar sign
      assert_includes tex, '\$50,000'
      # Snap! is mapped to \snap{} via the macros engine
      assert_includes tex, '\snap{}'
    end
  end

  def test_includes_publications_partial
    Dir.mktmpdir do |dir|
      tex = File.read(CV::Latex.build(output: File.join(dir, 'cv.tex')),
                      encoding: 'UTF-8')
      assert_includes tex, '\subsection{Conference Papers}'
      assert_includes tex, '\subsection{Conference and Workshop Presentations}'
    end
  end
end
