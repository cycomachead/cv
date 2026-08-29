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

  def test_md_embed_strips_page_title_but_keeps_front_matter
    Dir.mktmpdir do |dir|
      out = CV::Markdown.build_embed(output: File.join(dir, 'cv-embed.md'))
      md  = File.read(out, encoding: 'UTF-8')

      assert_match(/\A---\nlayout: cv\n/, md,
                   'jekyll front matter is preserved')
      # The site's cv layout renders the <h1> + subtitle from the front
      # matter, so the body must not repeat them.
      refute_includes md, '# Michael Ball'

      # Body content is still there.
      assert_includes md, '## Education'
      assert_includes md, '## Positions'
    end
  end

  # The site layout has no contact block of its own, so anything the embed
  # drops here is simply absent from mball.co/cv.
  def test_md_embed_keeps_contact_links_and_bio
    Dir.mktmpdir do |dir|
      md = File.read(CV::Markdown.build_embed(output: File.join(dir, 'cv-embed.md')),
                     encoding: 'UTF-8')
      basics = CV::Data.load.basics

      assert_includes md, '{:.contact}'
      assert_includes md, basics['email']
      assert_includes md, basics['homepage']
      Array(basics['profiles']).each { |p| assert_includes md, p['url'] }

      assert_includes md, '{:.bio}'
      assert_includes md, CV::Macros.to_md(basics['bio']['short'].strip)
    end
  end

  # Jekyll renders with the GFM parser and hard_wrap: false, so a soft line
  # break in the markdown is not a line break on the deployed page. Entry
  # blocks have to carry their own <br> or the employer, location, advisor and
  # thesis lines all run together into one paragraph.
  def test_entry_lines_break_under_jekylls_kramdown_settings
    Dir.mktmpdir do |dir|
      md = File.read(CV::Markdown.build(output: File.join(dir, 'cv.md')),
                     encoding: 'UTF-8')
      html = render_like_jekyll(md)

      entry = html[%r{<p class="entry">.*?</p>}m]
      refute_nil entry, 'no .entry paragraph in the rendered CV'
      assert_includes entry, '<br', 'entry lines collapsed into one line'
    end
  end

  # The preview only earns its "mirrors the deployed site" billing if both
  # renderings agree on where the line breaks are.
  def test_preview_line_breaks_match_the_deployed_render
    Dir.mktmpdir do |dir|
      md   = CV::Markdown.build(output: File.join(dir, 'cv.md'))
      html = File.read(CV::Preview.build(input: md, output: File.join(dir, 'cv.html')),
                       encoding: 'UTF-8')
      deployed = render_like_jekyll(File.read(md, encoding: 'UTF-8'))

      assert_equal deployed.scan('<br />').size, html.scan('<br />').size,
                   'preview and deployed renderings disagree on line breaks'
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

  # Author lists ending in an initial already carry a period; the entry
  # separator must not add a second one ("Malan, David J.. _Title_").
  def test_publications_never_double_up_periods
    Dir.mktmpdir do |dir|
      md = File.read(CV::Markdown.build(output: File.join(dir, 'cv.md')),
                     encoding: 'UTF-8')
      section = md[/^## Writing & Publications$.*?(?=^## )/m]
      refute_nil section, 'Publications section is missing'
      refute_match(/\.\./, section)
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

  private

  # Render cv.md the way the deployed Jekyll site does: GFM parser, auto ids,
  # and hard_wrap off (Jekyll's default — the gem's own default is true).
  def render_like_jekyll(md)
    require 'kramdown'
    require 'kramdown-parser-gfm'
    ::Kramdown::Document.new(md.sub(/\A---\n.*?\n---\n+/m, ''),
                             input: 'GFM', auto_ids: true,
                             hard_wrap: false).to_html
  end
end
