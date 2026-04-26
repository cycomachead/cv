# frozen_string_literal: true

require_relative 'test_helper'

class MacrosTest < Minitest::Test
  def test_snap_html_stylization
    assert_equal 'I love Snap<em>!</em>',
                 CV::Macros.to_html('I love Snap!')
  end

  def test_snapcon_and_snapshot_html
    html = CV::Macros.to_html('Snap!Con and Snap!shot')
    assert_includes html, 'Snap<em>!</em>Con'
    assert_includes html, 'Snap<em>!</em>shot'
  end

  def test_html_escapes_special_chars_but_keeps_macros
    html = CV::Macros.to_html('Snap! & Tell')
    assert_includes html, 'Snap<em>!</em>'
    assert_includes html, '&amp;'
  end

  def test_html_links_markdown
    html = CV::Macros.to_html('see [docs](https://example.com)')
    assert_includes html, '<a href="https://example.com">docs</a>'
  end

  def test_html_autolinks_bare_urls
    html = CV::Macros.to_html('visit https://example.com today')
    assert_includes html, '<a href="https://example.com">https://example.com</a>'
  end

  def test_latex_uses_snap_macro
    assert_equal 'I love \snap{}', CV::Macros.to_latex('I love Snap!')
  end

  def test_latex_links
    assert_equal 'see \href{https://example.com}{docs}',
                 CV::Macros.to_latex('see [docs](https://example.com)')
  end

  def test_authors_to_html_bolds_self
    html = CV::Macros.authors_to_html(['Garcia, Daniel', 'Ball, Michael'])
    assert_includes html, '<strong>Ball, Michael</strong>'
    assert_includes html, 'Garcia, Daniel'
  end

  def test_handles_nil_and_non_string_gracefully
    assert_equal '',  CV::Macros.to_html(nil)
    assert_equal '4', CV::Macros.to_html(4)
  end
end
