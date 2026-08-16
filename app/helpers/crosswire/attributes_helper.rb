# frozen_string_literal: true

module Crosswire
  # The only helper crosswire includes globally. Everything else is opt-in per
  # component, so installing the gem adds almost nothing to a consumer's helper surface.
  module AttributesHelper
    # Layer 0 — bring your own markup, keep our wiring.
    #
    #   <details <%= cw_attrs(d.root_attrs) %>>
    #     <summary <%= cw_attrs(d.trigger_attrs) %>>Details</summary>
    #     <div <%= cw_attrs(d.panel_attrs) %>>…</div>
    #   </details>
    #
    # Note the element structure there is completely different from what our partial
    # renders, and the controller still works — it only ever knew targets and values,
    # never markup. That is the whole composability argument in one example.
    #
    # Note the POSITIONAL argument to `tag.attributes`, not a `**` splat.
    # `TagBuilder#attributes` takes one positional hash and accepts no keywords, so
    # under Ruby 3 an empty `**{}` passes NO arguments at all and raises
    # `ArgumentError: wrong number of arguments (given 0, expected 1)`. An empty result
    # is legitimate — `Attributes.merge` documents an explicit `nil` as *deleting* a
    # key, so `cw_attrs(class: nil)` correctly produces `{}` — and must render as an
    # empty string, not blow up the page.
    def cw_attrs(*sources)
      tag.attributes(Crosswire::Attributes.merge(*sources))
    end

    # Build a component's presenter without rendering anything.
    #
    #   <% d = cw_presenter(:disclosure, id: "faq-1") %>
    def cw_presenter(name, **options)
      Crosswire::COMPONENTS.fetch(name.to_sym) do
        raise ArgumentError, "unknown crosswire component #{name.inspect}; " \
                             "known: #{Crosswire.component_names.join(", ")}"
      end.new(**options)
    end
  end
end
