# frozen_string_literal: true

require_relative 'test_helper'
require 'tmpdir'

class SiteTest < Minitest::Test
  def test_full_build_produces_expected_files
    Dir.mktmpdir do |dir|
      site = CV::Site.new(build_dir: dir)
      out  = site.build
      assert File.file?(out.join('index.html'))
      assert File.file?(out.join('resume.html'))
      assert File.file?(out.join('assets', 'style.css'))
    end
  end

  def test_build_output_is_well_formed_ish
    Dir.mktmpdir do |dir|
      out = CV::Site.new(build_dir: dir).build
      html = File.read(out.join('index.html'), encoding: 'UTF-8')
      # Sanity: every opening tag has a closing tag for these structural ones.
      %w[html head body main].each do |tag|
        assert_equal html.scan(/<#{tag}\b/).size,
                     html.scan(/<\/#{tag}>/).size,
                     "Mismatched <#{tag}> tags"
      end
    end
  end
end
