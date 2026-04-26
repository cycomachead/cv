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
  desc 'Build the HTML site to build/site/'
  task :build do
    out = CV::Site.new.build
    puts "wrote site to #{out}"
  end

  desc 'Serve the built HTML site locally on http://localhost:8000'
  task serve: :build do
    Dir.chdir(CV::BUILD_DIR.join('site')) do
      sh 'ruby -run -e httpd . -p 8000'
    end
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
    data = CV::Data.load
    bib  = CV::Bib.load
    rendered = CV::Renderer.new(format: :latex)
                           .render('publications.tex',
                                   data: data, bib: bib,
                                   locals: { section: { 'title' => 'Writing & Publications' } })
    FileUtils.mkdir_p(File.dirname(output))
    File.write(output, rendered)
    puts "wrote #{output}"
  end
end

namespace :dblp do
  desc 'Refresh dblp.bib from DBLP (default: ball-michael profile)'
  task :update do
    out = CV::DBLP.fetch
    puts "wrote #{out}"
  end
end

task default: %i[test site:build]
