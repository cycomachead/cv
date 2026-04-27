# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'

class MarkdownBuildTest < Minitest::Test
  def test_full_build_writes_cv_md
    Dir.mktmpdir do |dir|
      out = CV::Markdown.build(output: File.join(dir, 'cv.md'))
      assert File.file?(out)
      md = File.read(out, encoding: 'UTF-8')
      assert_match(/\A---\n/, md, 'jekyll front matter present by default')
      assert_includes md, '# Michael Ball'
      assert_includes md, 'Snap<em>!</em>'
    end
  end

  def test_preview_produces_html
    Dir.mktmpdir do |dir|
      md   = CV::Markdown.build(output: File.join(dir, 'cv.md'))
      html_out = CV::Preview.build(input: md, output: File.join(dir, 'cv.html'))
      assert File.file?(html_out)
      html = File.read(html_out, encoding: 'UTF-8')
      assert_includes html, '<h1 id="michael-ball">Michael Ball</h1>'
      assert_includes html, 'Snap<em>!</em>',
                      'Snap! styled inline in rendered HTML'
      refute_includes html, '---', 'front matter must be stripped from preview'
    end
  end
end
