# frozen_string_literal: true

require_relative 'test_helper'

class DataTest < Minitest::Test
  def setup
    @data = CV::Data.load
  end

  def test_basics_loaded
    assert_equal 'Michael Ball', @data.basics['name']
    assert_match(/berkeley/i, @data.basics['email'])
  end

  def test_basics_includes_bios
    bio = @data.basics['bio']
    refute_nil bio
    assert_kind_of String, bio['oneline']
    assert_kind_of String, bio['short']
    assert_kind_of String, bio['medium']
    assert_kind_of String, bio['long']
  end

  def test_education_is_array_of_hashes
    assert_kind_of Array, @data.education
    assert @data.education.all? { |e| e.is_a?(Hash) }
    assert(@data.education.any? { |e| e['degree'].include?('M.S.') })
  end

  def test_sections_drive_html_render
    keys = @data.sections.map { |s| s['template'] }
    %w[education positions awards publications].each do |k|
      assert_includes keys, k
    end
  end

  def test_publications_have_either_bib_or_authors_or_text
    @data.publications.each do |group|
      group['items'].each do |item|
        next if item['bib'] || item['text']
        assert item['authors'] || item['title'],
               "publication item must have bib, text, or authors+title: #{item.inspect}"
      end
    end
  end

  def test_publication_bib_keys_resolve
    bib = CV::Bib.load
    @data.publications.each do |group|
      group['items'].each do |item|
        key = item['bib']
        next unless key
        next if item['text'] # text fallback covers missing keys
        assert bib[key], "publication references missing bib key: #{key}"
      end
    end
  end
end
