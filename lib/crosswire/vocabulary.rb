# frozen_string_literal: true

module Crosswire
  # The reconciled 39-primitive vocabulary, grouped as in research/notes/08. Shipped
  # status is derived from the filesystem (see `bin/build_site.rb#shipped`), never
  # hand-maintained, so the table cannot drift from reality.
  #
  # Extracted out of bin/build_site.rb so it has exactly one source: the site build
  # and the UI-tier name-collision lint (`test/crosswire/ui_contract_audit_test.rb`,
  # spec §7.5 check 5 — a new UI component name must not collide with a name already
  # reserved in this vocabulary) both need it, and a constant duplicated between a
  # `bin/` script and a `test/` file is exactly the kind of drift this gem's own
  # contract audits exist to catch in OTHER people's code.
  VOCABULARY = {
    "Behaviour" => %w[dismiss persist intersection transition focus-trap roving-focus hotkey sync
                      timeout scroll-lock interval click-outside anchor activate autoscroll cable-channel],
    "Widget" => %w[dialog combobox popover disclosure tabs menu],
    "Form" => %w[autosubmit dirty-form direct-upload char-count nested-form drop-zone reveal
                 file-preview input-mask autogrow],
    "Collection" => %w[sortable selection chart],
    "Utility" => %w[relative-time confirm clipboard countdown]
  }.freeze
end
