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

    @inproceedings{abstract_only_2018,
      title  = {Some {Talk} ({Abstract} {Only})},
      author = {Ball, Michael},
      year   = {2018},
    }

    @inproceedings{abstract_only_colon_2016,
      title  = {Some {Workshop}: ({Abstract} {Only})},
      author = {Ball, Michael},
      year   = {2016},
    }
  BIB

  def setup
    @bib = CV::Bib.new(SAMPLE)
  end

  def test_parses_entries
    assert_equal 4, @bib.entries.size
    assert_equal %w[ball_test_2024 plain_2020 abstract_only_2018
                    abstract_only_colon_2016], @bib.keys
  end

  # ACM tags non-archival items "(Abstract Only)" in its DL export. That's an
  # export artifact, not part of the title, and never gets published.
  def test_strips_acm_abstract_only_tag_from_title
    assert_equal 'Some Talk', @bib['abstract_only_2018'].title
  end

  def test_strips_abstract_only_tag_with_dangling_colon
    assert_equal 'Some Workshop', @bib['abstract_only_colon_2016'].title
  end

  def test_no_published_bib_entry_leaks_the_abstract_only_tag
    titles = CV::Bib.load.entries.map(&:title)
    assert titles.any?, 'expected personal.bib to contain entries'
    refute(titles.any? { |t| t.match?(/abstract\s+only/i) },
           'an (Abstract Only) tag survived into a rendered title')
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
