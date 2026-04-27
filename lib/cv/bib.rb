# frozen_string_literal: true

require 'bibtex'

module CV
  # Thin shim over the `bibtex-ruby` gem. Templates only ever touch the small
  # surface defined here (`bib[key]`, `entry.authors / title / url / year`,
  # `entry[field]`), so swapping the underlying parser without changing the
  # rest of the codebase is a one-file change.
  class Bib
    # Wraps a single BibTeX::Entry with our preferred accessors. We strip
    # TeX brace-protection ({Snap!} → Snap!) and decode TeX escapes (\&amp; →
    # &) since the consumer wants display-ready text.
    class Entry
      def initialize(entry)
        @entry = entry
      end

      def key
        @entry.key.to_s
      end

      def type
        @entry.type.to_s
      end

      # entry["booktitle"], entry[:booktitle] — returns a cleaned string or nil.
      def [](field)
        v = @entry.respond_to?(field) ? @entry.send(field) : nil
        v.nil? || v.to_s.empty? ? nil : clean(v.to_s)
      end

      def title
        clean(@entry.title.to_s)
      end

      def authors
        return [] unless @entry.respond_to?(:author) && @entry.author
        @entry.author.map(&:to_s)
      end

      def year
        v = @entry.year
        v.nil? ? nil : v.to_s.to_i
      end

      def url
        return clean(@entry.url.to_s) if @entry.respond_to?(:url) && @entry.url
        return "https://doi.org/#{@entry.doi}" if @entry.respond_to?(:doi) && @entry.doi
        nil
      end

      private

      def clean(s)
        s.gsub(/[{}]/, '')                    # strip brace-protection
         .gsub(/\\&amp;/, '&').gsub(/\\&/, '&') # un-escape TeX-escaped HTML
      end
    end

    attr_reader :bibliography

    def self.load(path = CV::BIB_FILE)
      new(BibTeX.open(path.to_s))
    end

    def initialize(source)
      @bibliography = source.is_a?(BibTeX::Bibliography) ? source : BibTeX.parse(source.to_s)
    end

    def [](key)
      raw = @bibliography[key.to_s]
      raw ? Entry.new(raw) : nil
    end

    # All citation keys (skips @comment / @preamble / @string entries).
    def keys
      records.map { |e| e.key.to_s }
    end

    def entries
      records.map { |e| Entry.new(e) }
    end

    private

    def records
      @bibliography.select { |e| e.respond_to?(:key) && e.key }
    end
  end
end
