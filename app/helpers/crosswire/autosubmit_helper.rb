# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.autosubmit_for`,
  # `cw.autosubmit_attrs` (and `cw.autosubmit` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `autosubmit` is a behaviour, not a widget — it decorates a field you already have,
  # so it ships no batteries-included render form and no partial, only the two
  # standard forms.
  module AutosubmitHelper
    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.input(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <input <%= cw_attrs(cw.autosubmit_attrs(delay: 300), type: "search", name: "q") %>>
    def autosubmit_attrs(**options)
      Crosswire::Presenters::Autosubmit.new(**options).root_attrs
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <% cw.autosubmit_for(delay: 300, event: "change") do |a| %>
    #     <select <%= cw_attrs(a.root_attrs, name: "status") %>>
    #       ...
    #     </select>
    #   <% end %>
    def autosubmit_for(**options, &block)
      capture(Crosswire::Presenters::Autosubmit.new(**options), &block)
    end
  end
end
