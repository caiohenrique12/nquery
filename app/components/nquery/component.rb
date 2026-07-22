# frozen_string_literal: true

module Nquery
  class Component
    def self.render_in(view_context, **options, &block)
      new(**options).render_in(view_context, &block)
    end

    def render_in(view_context, &block)
      locals = template_locals(view_context, &block)
      view_context.render(partial: partial_name, locals: locals)
    end

    private

    def partial_name
      "nquery/#{self.class.name.demodulize.underscore}"
    end

    def template_locals(view_context, &block)
      locals = { component: self }
      locals[:content] = view_context.capture(&block) if block
      locals
    end
  end
end
