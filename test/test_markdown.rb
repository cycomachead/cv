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

  def test_md_includes_bio_short
    Dir.mktmpdir do |dir|
      md = File.read(CV::Markdown.build(output: File.join(dir, 'cv.md')),
                     encoding: 'UTF-8')
      assert_includes md, '{:.bio}'
      # First sentence of the short bio.
      assert_includes md, "I'm a software engineer and educator at UC Berkeley"
    end
  end

  def test_md_emits_ol_reversed_for_reverse_groups
    Dir.mktmpdir do |dir|
      md = File.read(CV::Markdown.build(output: File.join(dir, 'cv.md')),
                     encoding: 'UTF-8')
      assert_match(/<ol reversed start="\d+"/, md,
                   'reverse: true groups should emit an HTML5 reversed list')
    end
  end

  def test_md_marks_entry_paragraphs
    Dir.mktmpdir do |dir|
      md = File.read(CV::Markdown.build(output: File.join(dir, 'cv.md')),
                     encoding: 'UTF-8')
      # The IAL hint that styles role/title lines.
      assert md.scan('{:.entry}').size >= 5,
             "expected several {:.entry} markers, found #{md.scan('{:.entry}').size}"
    end
  end

  def test_preview_produces_html_with_sidebar_and_entry_class
    Dir.mktmpdir do |dir|
      md   = CV::Markdown.build(output: File.join(dir, 'cv.md'))
      out  = CV::Preview.build(input: md, output: File.join(dir, 'cv.html'))
      html = File.read(out, encoding: 'UTF-8')
      assert_includes html, '<h1 id="michael-ball">Michael Ball</h1>'
      assert_includes html, 'Snap<em>!</em>'

      # Sidebar TOC was generated and has h2 entries plus at least one h3.
      assert_includes html, 'class="toc"'
      assert_includes html, 'href="#education"'
      assert_includes html, 'href="#course-descriptions"'

      # Entry paragraphs got the .entry class via the kramdown IAL.
      assert_includes html, 'class="entry"'

      # Front matter was stripped.
      refute_match(/\A<!DOCTYPE html.*\n---\n/, html)
    end
  end
end
