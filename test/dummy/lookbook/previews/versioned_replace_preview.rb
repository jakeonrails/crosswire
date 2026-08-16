# frozen_string_literal: true

# **What it is.** `versioned_replace` — a Turbo Stream action that orders broadcasts by
# a monotonic `data-cw-version` instead of by arrival order, so a stale delivery
# (Action Cable promises no ordering across workers) cannot clobber a fresher one. See
# `crosswire/stream_actions.js` for the full write-up, including RULE 0
# (`broadcasts_refreshes` first) and the self-echo caveat.
#
# **What it composes from.** `Crosswire::Streams::Versioned#broadcast_versioned_replace_to`
# on the model side; `crosswire_version_attrs`/`crosswire_versioned_replace` in
# `Crosswire::StreamsHelper`; `registerCrosswireStreamActions` on the client. This
# preview skips the model/broadcast layer entirely and drives
# `Turbo.renderStreamMessage` directly with hand-built `<turbo-stream
# action="versioned_replace">` payloads — the same client entry point a real Action
# Cable delivery ultimately reaches, and, like `preserve_preview`'s "simulate morph"
# button, a dev/test-only shortcut wired through the dummy app's own importmap.
#
# **The seam worth studying** is the "Send an OLDER version" button: it visibly does
# nothing to the box's content — that IS the correct behaviour, not a bug — and the box
# bounces briefly (a `cw--stream:skipped` listener toggling a CSS animation class) so
# the rejection itself is visible rather than silent.
#
# **Rule 0.** Prefer `broadcasts_refreshes` — a stale render is impossible by
# construction there. Reach for `broadcast_replace_to` (and `versioned_replace`, if
# reordering turns out to matter for it) only after choosing that over
# `broadcasts_refreshes` for a measured load/latency reason.
class VersionedReplacePreview < Lookbook::Preview
  # Starts the box at version 1. "Apply a NEWER version" sends
  # `data-cw-version` one higher than whatever the box currently shows, and applies.
  # "Send an OLDER version" sends `data-cw-version="1"` (or whatever the box started
  # at) regardless of how far the box has since advanced — always stale, always
  # skipped, always bounces.
  def default
    render_with_template(template: "versioned_replace_preview/default")
  end
end
