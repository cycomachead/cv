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

  # A \href label is ordinary horizontal-mode text, so LaTeX specials in it must
  # be escaped or the build aborts ("You can't use `macro parameter character
  # #'"). The URL argument stays verbatim — hyperref wants it that way.
  def test_escapes_href_labels_but_not_urls
    Dir.mktmpdir do |dir|
      tex = File.read(CV::Latex.build(output: File.join(dir, 'cv.tex')),
                      encoding: 'UTF-8')
      # EECS award anchors: raw # in the URL, escaped # in the label.
      assert_includes tex, '\href{https://www2.eecs.berkeley.edu/Students/Awards/#11}' \
                           '{https://www2.eecs.berkeley.edu/Students/Awards/\#11}'
      # Underscores in a publication URL get the same treatment.
      assert_includes tex, 'full\_pdfs'
      refute_match(/\\href\{[^}]*\}\{[^}]*[^\\]#/, tex,
                   'no unescaped # should survive in an \href label')
    end
  end

  def test_referee_phones_are_redacted_by_default
    Dir.mktmpdir do |dir|
      tex = File.read(CV::Latex.build(output: File.join(dir, 'cv.tex')),
                      encoding: 'UTF-8')
      # The numbers are wrapped, not inlined: \refphone expands to nothing
      # unless \unredacted is defined.
      CV::Data.load.references.filter_map { |r| r['phone'] }.each do |phone|
        assert_includes tex, "\\refphone{#{phone}}"
        refute_includes tex, "\\newline #{phone}"
      end
      assert_includes tex, '\newcommand{\refphone}[1]{}'
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
