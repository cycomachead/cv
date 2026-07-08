# frozen_string_literal: true

require_relative 'test_helper'

class BibTest < Minitest::Test
  SAMPLE = <<~BIB
    @inproceedings{ball_test_2024,
      title    = {Title with {Snap!} {Brace}},
      author   = {Ball, Michael and Garcia, Daniel},
      year     = {2024},
      url      = {https://example.com/x},
      booktitle = {Proceedings of Test Conf},
    }

    @article{plain_2020,
      author = "Lastname, Firstname",
      title = "A Title",
      year = 2020,
    }
  BIB

  def setup
    @bib = CV::Bib.new(SAMPLE)
  end

  def test_parses_entries
    assert_equal 2, @bib.entries.size
    assert_equal %w[ball_test_2024 plain_2020], @bib.keys
  end

  def test_lookup_by_key
    entry = @bib['ball_test_2024']
    refute_nil entry
    assert_equal 'inproceedings', entry.type
  end

  def test_strips_brace_protection_from_title
    assert_equal 'Title with Snap! Brace', @bib['ball_test_2024'].title
  end

  def test_authors_split_on_and
    assert_equal ['Ball, Michael', 'Garcia, Daniel'],
                 @bib['ball_test_2024'].authors
  end

  def test_year_returns_int
    assert_equal 2024, @bib['ball_test_2024'].year
  end

  def test_url_falls_back_to_doi
    bib = CV::Bib.new('@misc{x, doi = {10.1/abc}}')
    assert_equal 'https://doi.org/10.1/abc', bib['x'].url
  end

  def test_quoted_field_values
    assert_equal 'A Title', @bib['plain_2020'].title
  end

  def test_personal_bib_loads
    bib = CV::Bib.load
    assert bib.entries.size >= 20, "expected ≥20 entries, got #{bib.entries.size}"
    sigcse = bib['ball_beauty_2022']
    refute_nil sigcse
    assert_includes sigcse.authors.first, 'Ball'
  end
end
