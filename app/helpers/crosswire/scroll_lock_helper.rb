# frozen_string_literal: true

module Crosswire
  # Include per-component rather than globally:
  #
  #   class ApplicationController < ActionController::Base
  #     helper Crosswire::ScrollLockHelper
  #   end
  #
  # `scroll-lock` is a behaviour, not a widget — it decorates an element you already
  # have, so it ships no batteries-included render form and no partial, only the two
  # standard forms.
  module ScrollLockHelper
    # Yields the presenter, renders no markup of ours. Stack it on the same element as
    # `cw--dialog` or a drawer's own controller:
    #
    #   <%= crosswire_scroll_lock_for active: @dialog_open do |s| %>
    #     <dialog <%= cw_attrs(s.root_attrs, data: { controller: "cw--dialog" }) %>>
    #       …
    #     </dialog>
    #   <% end %>
    def crosswire_scroll_lock_for(**options)
      yield Crosswire::Presenters::ScrollLock.new(**options)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <dialog <%= cw_attrs(crosswire_scroll_lock_attrs(active: @dialog_open),
    #             data: { controller: "cw--dialog" }) %>>
    #     …
    #   </dialog>
    def crosswire_scroll_lock_attrs(**options)
      Crosswire::Presenters::ScrollLock.new(**options).root_attrs
    end
  end
end
