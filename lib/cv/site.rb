# frozen_string_literal: true

require 'fileutils'
require 'pathname'

module CV
  # Orchestrates building the static HTML site from YAML data + ERB templates.
  # Output is written under build/site/.
  class Site
    OUTPUT_SUBDIR = 'site'

    def initialize(build_dir: CV::BUILD_DIR, data: nil, bib: nil)
      @output    = Pathname.new(build_dir).join(OUTPUT_SUBDIR)
      @data      = data || CV::Data.load
      @bib       = bib  || CV::Bib.load
      @html      = CV::Renderer.new(format: :html)
    end

    def build
      FileUtils.mkdir_p(@output)
      write('index.html',  @html.render('index',  data: @data, bib: @bib))
      write('resume.html', @html.render('resume', data: @data, bib: @bib))
      copy_assets
      @output
    end

    private

    def write(name, content)
      @output.join(name).write(content)
    end

    def copy_assets
      assets_src = CV::TEMPLATE_DIR.join('html', 'assets')
      return unless assets_src.directory?
      FileUtils.cp_r(assets_src, @output)
    end
  end
end
