# frozen_string_literal: true

require 'erb'
require 'pathname'

module CV
  # Wraps ERB templating. Templates live in templates/<format>/<name>.erb.
  # The renderer evaluates them in a Context that exposes the loaded data
  # and the macros engine, so templates can call e.g. `h(text)` to escape and
  # convert inline markers, or look up `bib['key']`.
  class Renderer
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
        when :html  then CV::Macros.to_html(text)
        when :latex then CV::Macros.to_latex(text)
        else text.to_s
        end
      end

      # Render a list of authors with the user's name bolded (HTML only).
      def authors(list)
        case @format
        when :html  then CV::Macros.authors_to_html(list)
        when :latex then list.map { |a| CV::Macros.to_latex(a) }.join('; ')
        else list.join('; ')
        end
      end

      # Render a partial template by name. Useful so the layout template can
      # delegate to a section-specific template.
      def partial(name, locals = {})
        @helpers[:render_partial].call(name, locals)
      end

      # Allow data.x and bib.y access in templates without the `@` prefix.
      def get_binding
        binding
      end
    end

    def initialize(template_dir: CV::TEMPLATE_DIR, format: :html)
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
      # Expose locals as singleton methods on the context so templates can
      # reference them by name.
      locals.each { |k, v| ctx.define_singleton_method(k) { v } }

      template.result(ctx.get_binding)
    end

    private

    def resolve(name)
      ext = (@format == :html ? 'html' : 'tex')
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
