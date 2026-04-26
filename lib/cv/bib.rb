# frozen_string_literal: true

require 'pathname'

module CV
  # Tiny BibTeX parser. Handles the subset of BibTeX used in personal.bib:
  # @type{key, field = {value} or "value", ...}. Brace-balanced values are
  # supported (so titles like "{Snap!}" work). String concatenation, @string
  # macros, @comment, and @preamble are not supported — the bib file in this
  # repo doesn't use them.
  class Bib
    Entry = Struct.new(:key, :type, :fields, keyword_init: true) do
      def [](field)
        v = fields[field.to_s]
        v.nil? ? nil : v
      end

      def authors
        return [] unless self[:author]
        self[:author].split(/\s+and\s+/).map(&:strip)
      end

      def year
        self[:year]&.to_i
      end

      def url
        self[:url] || (self[:doi] ? "https://doi.org/#{self[:doi]}" : nil)
      end

      def title
        # Strip BibTeX brace-protection: {Snap!} → Snap!
        (self[:title] || '').gsub(/[{}]/, '')
      end
    end

    attr_reader :entries

    def self.load(path = CV::BIB_FILE)
      new(File.read(path, encoding: 'UTF-8'))
    end

    def initialize(source)
      @source = source
      @entries = parse(source)
    end

    def [](key)
      @entries.find { |e| e.key == key.to_s }
    end

    def keys
      @entries.map(&:key)
    end

    private

    def parse(src)
      entries = []
      i = 0
      while i < src.length
        # Find the next '@' starting a record.
        i = src.index('@', i)
        break unless i

        # Read entry type: @type{
        m = src[i..].match(/\A@(\w+)\s*\{/)
        unless m
          i += 1
          next
        end
        type = m[1].downcase
        i += m[0].length

        # Skip @comment / @preamble / @string blocks: read until balanced }.
        if %w[comment preamble string].include?(type)
          i = skip_balanced(src, i)
          next
        end

        # Citation key up to the first comma at brace-depth 0.
        key_end = src.index(',', i)
        key = src[i...key_end].strip
        i = key_end + 1

        fields = {}
        loop do
          # Skip whitespace.
          i += 1 while i < src.length && src[i].match?(/\s/)
          break if i >= src.length || src[i] == '}'

          name_end = src.index('=', i)
          break unless name_end

          name = src[i...name_end].strip.downcase
          i = name_end + 1
          i += 1 while i < src.length && src[i].match?(/\s/)

          value, i = read_value(src, i)
          fields[name] = value

          i += 1 while i < src.length && src[i].match?(/[\s,]/)
        end
        i += 1 if i < src.length && src[i] == '}'

        entries << Entry.new(key: key, type: type, fields: fields)
      end
      entries
    end

    # Read a BibTeX value starting at i. Values are either {balanced braces},
    # "quoted strings", or bare numbers/identifiers.
    def read_value(src, i)
      case src[i]
      when '{'
        depth = 0
        start = i
        while i < src.length
          case src[i]
          when '{' then depth += 1
          when '}'
            depth -= 1
            if depth == 0
              return [src[(start + 1)...i], i + 1]
            end
          end
          i += 1
        end
        [src[(start + 1)..], i]
      when '"'
        start = i + 1
        i += 1
        i += 1 while i < src.length && src[i] != '"'
        [src[start...i], i + 1]
      else
        start = i
        i += 1 while i < src.length && !src[i].match?(/[,\s}]/)
        [src[start...i], i]
      end
    end

    # Skip a brace-balanced @comment/@string/@preamble block. We've already
    # consumed the opening '{'.
    def skip_balanced(src, i)
      depth = 1
      while i < src.length && depth > 0
        case src[i]
        when '{' then depth += 1
        when '}' then depth -= 1
        end
        i += 1
      end
      i
    end
  end
end
