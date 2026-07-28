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

      # Layout wrapper is present so the dark-mode toggle (via data-theme on
      # .cv-layout) and the scoped CSS find their root.
      assert_includes html, 'class="cv-layout"'

      # Sidebar contains downloads, TOC, theme toggle.
      assert_includes html, 'class="cv-sidebar"'
      assert_includes html, 'class="cv-downloads"'
      assert_includes html, 'cv-btn cv-btn-primary'
      assert_includes html, 'Download CV (PDF)'
      # The résumé is a de-emphasised text link, not a second button.
      assert_includes html, 'class="cv-download-alt"'
      assert_includes html, '1-page résumé'
      refute_includes html, 'cv-btn-secondary'
      assert_includes html, 'class="cv-toc"'
      assert_includes html, 'data-cv-theme-toggle'
      assert_includes html, 'href="#education"'
      assert_includes html, 'href="#course-descriptions"'

      # Theme toggle + scroll spy scripts are inlined.
      assert_includes html, "STORAGE_KEY = 'cv-theme'"
      assert_includes html, 'data-cv-theme-toggle'
      assert_includes html, "var ACTIVE = 'is-active';"
      refute_includes html, '{{NAV_SCRIPT}}'

      # Entry paragraphs got the .entry class via the kramdown IAL.
      assert_includes html, 'class="entry"'

      # Front matter was stripped.
      refute_match(/\A<!DOCTYPE html.*\n---\n/, html)
    end
  end

  def test_md_embed_strips_page_header_but_keeps_front_matter
    Dir.mktmpdir do |dir|
      out = CV::Markdown.build_embed(output: File.join(dir, 'cv-embed.md'))
      md  = File.read(out, encoding: 'UTF-8')

      assert_match(/\A---\nlayout: cv\n/, md,
                   'jekyll front matter is preserved')
      refute_includes md, '# Michael Ball'
      refute_includes md, '{:.contact}'
      refute_includes md, '{:.bio}'

      # Body content is still there.
      assert_includes md, '## Education'
      assert_includes md, '## Positions'
    end
  end

  def test_md_links_course_sites_after_descriptions
    Dir.mktmpdir do |dir|
      md = File.read(CV::Markdown.build(output: File.join(dir, 'cv.md')),
                     encoding: 'UTF-8')
      { 'CS 10'                => 'cs10.org',
        'CS 88 / DATA C88C'    => 'c88c.org',
        'CS 169A'              => 'saasbook.info',
        'DATA 101 / CS C187'   => 'data101.org' }.each do |code, host|
        line = md.lines.find { |l| l.start_with?("- **#{code}**") }
        refute_nil line, "no course line for #{code}"
        assert_match(/\[#{Regexp.escape(host)}\]\(https:\/\/#{Regexp.escape(host)}\)\s*\z/,
                     line.strip, "#{code} should end with a link to #{host}")
      end
    end
  end

  def test_md_withholds_referee_contact_details
    Dir.mktmpdir do |dir|
      md = File.read(CV::Markdown.build(output: File.join(dir, 'cv.md')),
                     encoding: 'UTF-8')
      section = md[/^## References$.*/m]
      refute_nil section, 'References section is missing'
      assert_includes section, 'References available upon request.'
      # The web CV is public — no referee names, emails, or phone numbers.
      # (Names are checked only inside the section: Daniel Garcia also shows
      # up legitimately as the M.S. thesis advisor.)
      CV::Data.load.references.each do |ref|
        refute_includes section, ref['name']
        refute_includes md, ref['email']
        refute_includes md, ref['phone'] if ref['phone']
      end
    end
  end

  # The embed is what actually deploys, so assert it independently rather than
  # relying on it sharing a code path with the full build.
  def test_md_embed_withholds_referee_contact_details
    Dir.mktmpdir do |dir|
      md = File.read(CV::Markdown.build_embed(output: File.join(dir, 'cv-embed.md')),
                     encoding: 'UTF-8')
      section = md[/^## References$.*/m]
      refute_nil section, 'References section is missing'
      assert_includes section, 'References available upon request.'
      CV::Data.load.references.each do |ref|
        refute_includes section, ref['name']
        refute_includes md, ref['email']
        refute_includes md, ref['phone'] if ref['phone']
      end
    end
  end

  def test_sidebar_fragment_has_downloads_toc_toggle
    Dir.mktmpdir do |dir|
      CV::Markdown.build(output: File.join(dir, 'cv.md'))
      # Hand the sidebar a tiny rendered body so we don't depend on the full
      # markdown→html round-trip for this test.
      body = <<~HTML
        <h2 id="education">Education</h2>
        <h3 id="degree">Degree</h3>
        <h2 id="positions">Positions</h2>
      HTML
      out = CV::Sidebar.build(output: File.join(dir, 'cv-sidebar.html'),
                              html_body: body)
      html = File.read(out, encoding: 'UTF-8')

      assert_includes html, 'class="cv-sidebar"'
      assert_includes html, 'class="cv-btn cv-btn-primary"'
      assert_includes html, 'href="/michael-ball-cv.pdf"'
      assert_includes html, 'href="resume.pdf"'
      assert_includes html, 'href="#education"'
      assert_includes html, 'href="#degree"'
      assert_includes html, 'href="#positions"'
      assert_includes html, 'data-cv-theme-toggle'
      # No <html>/<body> wrapper — this is a fragment to be included.
      refute_includes html, '<html'
      refute_includes html, '<body'
    end
  end

  def test_sidebar_accepts_custom_pdf_urls
    body = '<h2 id="x">X</h2>'
    html = CV::Sidebar.render(html_body: body,
                              cv_pdf_url: '/cv-full.pdf',
                              resume_pdf_url: '/one-page.pdf')
    assert_includes html, 'href="/cv-full.pdf"'
    assert_includes html, 'href="/one-page.pdf"'
  end
end
