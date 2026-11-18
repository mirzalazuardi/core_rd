# frozen_string_literal: true

require "roda"

class Roda
  module RodaPlugins
    # Minimal render_phlex plugin: Phlex is called directly, no Tilt/ERB.
    module RenderPhlex
      module InstanceMethods
        def render_phlex(component, status: nil)
          response.status = status if status
          response["Content-Type"] ||= "text/html; charset=utf-8"
          component = component.new if component.is_a?(Class)
          component.call
        end
      end
    end

    register_plugin(:render_phlex, RenderPhlex)
  end
end
