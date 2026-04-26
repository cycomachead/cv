# frozen_string_literal: true

require_relative 'test_helper'

class RendererTest < Minitest::Test
  def setup
    @data = CV::Data.load
    @bib  = CV::Bib.load
  end

  def test_renders_index_html
    r = CV::Renderer.new(format: :html)
    html = r.render('index', data: @data, bib: @bib)
    assert_match(/<h1[^>]*>Michael Ball<\/h1>/, html)
    assert_includes html, 'Education'
    assert_includes html, 'Publications'
  end

  def test_index_html_styles_snap_correctly
    r = CV::Renderer.new(format: :html)
    html = r.render('index', data: @data, bib: @bib)
    assert_includes html, 'Snap<em>!</em>',
                    'Snap! macro should be styled'
  end

  def test_renders_one_page_resume
    r = CV::Renderer.new(format: :html)
    html = r.render('resume', data: @data, bib: @bib)
    assert_match(/<h1[^>]*>Michael Ball<\/h1>/, html)
    assert_includes html, 'Education'
  end

  def test_renders_publications_latex_fragment
    r = CV::Renderer.new(format: :latex)
    tex = r.render('publications.tex', data: @data, bib: @bib,
                                       locals: { section: { 'title' => 'Publications' } })
    assert_includes tex, '\section{Publications}'
    assert_includes tex, '\snap{}',
                    'LaTeX output should use \snap{} macro'
    assert_includes tex, '\href{'
  end
end
