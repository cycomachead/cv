# frozen_string_literal: true

require_relative 'test_helper'

class MacrosTest < Minitest::Test
  def test_md_snap_uses_inline_em
    # We deliberately emit raw <em> rather than `*!*` so a thesis title that
    # happens to be wrapped in markdown italic still renders cleanly.
    assert_equal 'I love Snap<em>!</em>', CV::Macros.to_md('I love Snap!')
  end

  def test_md_snapcon_and_snapshot
    assert_includes CV::Macros.to_md('Snap!Con and Snap!shot'), 'Snap<em>!</em>Con'
    assert_includes CV::Macros.to_md('Snap!Con and Snap!shot'), 'Snap<em>!</em>shot'
  end

  def test_html_snap_stylization_still_works
    assert_equal 'I love Snap<em>!</em>', CV::Macros.to_html('I love Snap!')
  end

  def test_latex_uses_snap_macro
    assert_equal 'I love \snap{}', CV::Macros.to_latex('I love Snap!')
  end

  def test_latex_escapes_special_chars
    assert_equal 'AT\&T \$50,000 100\% \#1 foo\_bar',
                 CV::Macros.to_latex('AT&T $50,000 100% #1 foo_bar')
  end

  def test_latex_link_keeps_url_intact
    # The bare # and _ inside a URL inside \href{} must NOT be backslash-
    # escaped (they break the link), even though we escape them in prose.
    out = CV::Macros.to_latex('[docs](https://ex.com/foo_bar#sec)')
    assert_equal '\\href{https://ex.com/foo_bar#sec}{docs}', out
  end

  def test_authors_md_bolds_self
    md = CV::Macros.authors_to_md(['Garcia, Daniel', 'Ball, Michael'])
    assert_includes md, '**Ball, Michael**'
    assert_includes md, 'Garcia, Daniel'
  end

  def test_authors_html_bolds_self
    html = CV::Macros.authors_to_html(['Ball, Michael'])
    assert_includes html, '<strong>Ball, Michael</strong>'
  end

  def test_handles_nil_and_non_string
    assert_equal '', CV::Macros.to_md(nil)
    assert_equal '4', CV::Macros.to_md(4)
  end
end
