# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.scroll_lock_for`,
  # `cw.scroll_lock_attrs` (and `cw.scroll_lock` for components that ship a
  # partial) — or the canonical `crosswire.` in place of `cw.`.
  #
  # `scroll-lock` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the two
  # standard forms.
  module ScrollLockHelper
    # Yields the presenter, renders no markup of ours. Stack it on the same element as
    # `cw--dialog` or a drawer's own controller:
    #
    #   <%= cw.scroll_lock_for active: @dialog_open do |s| %>
    #     <dialog <%= cw_attrs(s.root_attrs, data: { controller: "cw--dialog" }) %>>
    #       …
    #     </dialog>
    #   <% end %>
    def scroll_lock_for(**options, &block)
      capture(Crosswire::Presenters::ScrollLock.new(**options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <dialog <%= cw_attrs(cw.scroll_lock_attrs(active: @dialog_open),
    #             data: { controller: "cw--dialog" }) %>>
    #     …
    #   </dialog>
    def scroll_lock_attrs(**options)
      Crosswire::Presenters::ScrollLock.new(**options).root_attrs
    end
  end
end
