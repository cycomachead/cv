# frozen_string_literal: true

require 'erb'
require 'pathname'

module CV
  # Wraps ERB templating. Templates live in templates/<format>/<name>.erb.
  # Supported formats: :markdown (default — feeds into kramdown / Jekyll) and
  # :latex (for the regenerable publications fragment). The :html format is
  # not used directly any more — Markdown is the canonical authoring format
  # and HTML is a downstream rendering of it.
  class Renderer
    EXTENSIONS = { markdown: 'md', latex: 'tex' }.freeze

    class Context
      attr_reader :data, :bib

      def initialize(data:, bib:, format:, helpers: {})
        @data    = data
        @bib     = bib
        @format  = format
        @helpers = helpers
      end

      # Render inline text — chooses the right macro pass for the format.
      def h(text)
        case @format
        when :markdown then CV::Macros.to_md(text)
        when :latex    then CV::Macros.to_latex(text)
        else text.to_s
        end
      end

      # Render a list of authors with the user's name bolded.
      def authors(list)
        case @format
        when :markdown then CV::Macros.authors_to_md(list)
        when :latex    then CV::Macros.authors_to_latex(list)
        else list.join('; ')
        end
      end

      # Auto-link a bare URL appropriately for the output format.
      #
      # For LaTeX the *label* is ordinary horizontal-mode text, so it has to be
      # escaped — a URL fragment like `.../Awards/#11` otherwise reaches the
      # typesetter as a macro parameter character and aborts the build. The URL
      # argument is left verbatim, which is what hyperref wants.
      def link(url, label = nil)
        return '' if url.nil? || url.empty?
        label ||= url.sub(%r{^https?://}, '')
        case @format
        when :markdown then "[#{label}](#{url})"
        when :latex    then "\\href{#{url}}{#{escape_latex(label)}}"
        else "<a href=\"#{url}\">#{label}</a>"
        end
      end

      def escape_latex(text)
        text.to_s.gsub(/[&%$#_]/, CV::Macros::LATEX_ESCAPES)
      end

      # Render a partial template by name (relative to the same format dir).
      def partial(name, locals = {})
        @helpers[:render_partial].call(name, locals)
      end

      def get_binding
        binding
      end
    end

    def initialize(template_dir: CV::TEMPLATE_DIR, format: :markdown)
      @template_dir = Pathname.new(template_dir)
      @format       = format
    end

    def render(template_name, data:, bib:, locals: {})
      template_path = resolve(template_name)
      template = ERB.new(template_path.read(encoding: 'UTF-8'), trim_mode: '-')
      template.filename = template_path.to_s

      ctx = Context.new(
        data:    data,
        bib:     bib,
        format:  @format,
        helpers: { render_partial: ->(name, lcs) { render(name, data: data, bib: bib, locals: lcs) } }
      )
      locals.each { |k, v| ctx.define_singleton_method(k) { v } }

      template.result(ctx.get_binding)
    end

    private

    def resolve(name)
      ext = EXTENSIONS.fetch(@format, @format.to_s)
      candidates = [
        @template_dir.join(@format.to_s, "#{name}.#{ext}.erb"),
        @template_dir.join(@format.to_s, "#{name}.erb"),
        @template_dir.join(@format.to_s, name)
      ]
      hit = candidates.find(&:file?)
      raise "Template not found: #{name} (looked in #{candidates.join(', ')})" unless hit
      hit
    end
  end
end
