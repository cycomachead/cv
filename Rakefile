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

  desc 'Build a standalone HTML preview (build/cv.html)'
  task preview: :md do
    out = CV::Preview.build
    puts "wrote #{out}"
  end

  desc 'Stage cv.md + PDFs for the cycomachead.github.io/cv/ deploy'
  task deploy_out: :md do
    deploy = CV::BUILD_DIR.join('deploy')
    FileUtils.mkdir_p(deploy)
    FileUtils.cp(CV::Markdown::DEFAULT_OUTPUT, deploy.join('index.md'))
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

namespace :pubs do
  desc 'Render publications.tex from YAML + bib (default: build/publications.tex)'
  task :tex, [:output] do |_, args|
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
