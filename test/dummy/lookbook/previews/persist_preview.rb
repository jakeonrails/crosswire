# frozen_string_literal: true

# **What it is.** Persist an element's value — or any attribute — to `localStorage` or
# `sessionStorage` and restore it on connect. A *behaviour* — no markup, no partial.
#
# **What it composes from.** `Crosswire::Presenters::Persist` validates `storage` up front
# (an unknown value raises in Ruby, at render time, rather than failing silently in the
# browser) and emits `key`, `attribute`, `storage`, `debounce` as values. The controller
# degrades gracefully when storage throws — Safari private mode, a full quota, a blocked
# third-party context — rather than taking the page down.
#
# **Rule 0.** If the state matters, put it on the server. This is for genuinely local,
# genuinely disposable preferences: a filter box, a collapsed sidebar, a dismissed hint.
class PersistPreview < Lookbook::Preview
  # @param key text "Storage key"
  # @param storage select "~ [local, session]"
  # @param debounce number "Milliseconds to wait after the last change before writing"
  def default(key: "search-filter", storage: "local", debounce: 200)
    render_with_template(
      template: "persist_preview/default",
      locals: {key: key, storage: storage, debounce: debounce}
    )
  end

  # `attribute:` persists a boolean attribute rather than a value, which makes a plain
  # `<details>` remember its own state with no other JavaScript involved.
  def details_open_state
    render_with_template(template: "persist_preview/details_open_state")
  end
end
