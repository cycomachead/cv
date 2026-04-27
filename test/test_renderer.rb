# frozen_string_literal: true

require_relative 'test_helper'

class RendererTest < Minitest::Test
  def setup
    @data = CV::Data.load
    @bib  = CV::Bib.load
  end

  def test_renders_canonical_markdown
    md = CV::Renderer.new(format: :markdown)
                     .render('cv', data: @data, bib: @bib,
                                   locals: { jekyll_front_matter: false })
    assert_match(/^# Michael Ball$/, md)
    assert_includes md, '## Education'
    assert_includes md, '## Writing & Publications'
  end

  def test_markdown_styles_snap_inline
    md = CV::Renderer.new(format: :markdown)
                     .render('cv', data: @data, bib: @bib,
                                   locals: { jekyll_front_matter: false })
    assert_includes md, 'Snap<em>!</em>',
                    'Snap! macro should expand to inline <em>! HTML in markdown'
  end

  def test_markdown_jekyll_front_matter_optional
    with_fm = CV::Renderer.new(format: :markdown).render(
      'cv', data: @data, bib: @bib, locals: { jekyll_front_matter: true })
    no_fm   = CV::Renderer.new(format: :markdown).render(
      'cv', data: @data, bib: @bib, locals: { jekyll_front_matter: false })
    assert_match(/\A---\n/, with_fm)
    refute_match(/\A---\n/, no_fm)
  end

  def test_renders_publications_latex_fragment
    tex = CV::Renderer.new(format: :latex)
                      .render('publications.tex', data: @data, bib: @bib,
                              locals: { section: { 'title' => 'Publications' } })
    assert_includes tex, '\section{Publications}'
    assert_includes tex, '\snap{}',
                    'LaTeX output should use \snap{} macro'
    assert_includes tex, '\href{'
  end
end
