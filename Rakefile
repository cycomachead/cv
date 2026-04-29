# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path('lib', __dir__)
require 'cv'
require 'rake/testtask'
require 'fileutils'

Rake::TestTask.new(:test) do |t|
  t.libs    << 'lib'
  t.libs    << 'test'
  t.pattern = 'test/test_*.rb'
  t.warning = false
end

namespace :site do
  desc 'Render the canonical Markdown CV (build/cv.md)'
  task :md do
    out = CV::Markdown.build
    puts "wrote #{out}"
  end

  desc 'Render the header-stripped Markdown for the Jekyll embed (build/cv-embed.md)'
  task :md_embed do
    out = CV::Markdown.build_embed
    puts "wrote #{out}"
  end

  desc 'Build a standalone HTML preview (build/cv.html)'
  task preview: :md do
    out = CV::Preview.build
    puts "wrote #{out}"
  end

  desc 'Build the cv-sidebar.html fragment for the Jekyll site (build/cv-sidebar.html)'
  task sidebar: :md do
    out = CV::Sidebar.build
    puts "wrote #{out}"
  end

  desc 'Build the embed bundle: cv-embed.md + cv-sidebar.html + cv.css + cv-theme.js'
  task embed: %i[md_embed sidebar] do
    %w[preview.css cv-theme.js].each do |asset|
      src  = CV::TEMPLATE_DIR.join('markdown', asset)
      dest = CV::BUILD_DIR.join(asset == 'preview.css' ? 'cv.css' : asset)
      FileUtils.cp(src, dest)
      puts "wrote #{dest}"
    end
  end

  desc 'Stage cv-embed.md + sidebar + assets + PDFs for the cycomachead.github.io/cv/ deploy'
  task deploy_out: %i[md_embed sidebar] do
    deploy = CV::BUILD_DIR.join('deploy')
    FileUtils.mkdir_p(deploy)
    FileUtils.cp(CV::Markdown::EMBED_DEFAULT_OUTPUT,    deploy.join('index.md'))
    FileUtils.cp(CV::Sidebar::DEFAULT_OUTPUT,           deploy.join('cv-sidebar.html'))
    FileUtils.cp(CV::TEMPLATE_DIR.join('markdown', 'preview.css'), deploy.join('cv.css'))
    FileUtils.cp(CV::TEMPLATE_DIR.join('markdown', 'cv-theme.js'), deploy.join('cv-theme.js'))
    %w[main.pdf one-page-resume.pdf].each do |pdf|
      src = CV::ROOT.join(pdf)
      next unless src.exist?
      FileUtils.cp(src, deploy.join(pdf == 'main.pdf' ? 'cv.pdf' : 'resume.pdf'))
    end
    puts "staged #{deploy}"
  end

  desc 'Remove the build directory'
  task :clean do
    FileUtils.rm_rf(CV::BUILD_DIR)
    puts "removed #{CV::BUILD_DIR}"
  end
end

namespace :tex do
  desc 'Render the full single-file LaTeX CV from YAML+bib (build/cv.tex)'
  task :build do
    out = CV::Latex.build
    puts "wrote #{out}"
  end

  desc 'Render only the publications fragment (build/publications.tex)'
  task :pubs, [:output] do |_, args|
    output = args[:output] || CV::BUILD_DIR.join('publications.tex')
    rendered = CV::Renderer.new(format: :latex)
                           .render('publications.tex',
                                   data: CV::Data.load, bib: CV::Bib.load,
                                   locals: { section: { 'title' => 'Writing & Publications' } })
    FileUtils.mkdir_p(File.dirname(output))
    File.write(output, rendered)
    puts "wrote #{output}"
  end
end

task default: %i[test site:md site:preview]
