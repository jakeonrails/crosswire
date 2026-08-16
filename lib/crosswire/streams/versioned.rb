# frozen_string_literal: true

module Crosswire
  module Streams
    # Model-side half of `versioned_replace` (see `crosswire/stream_actions.js` for the
    # client half and the full RULE 0 / self-echo writeup — read that first).
    #
    # `include Crosswire::Streams::Versioned` alongside your model's ordinary
    # `Turbo::Broadcastable` usage (every `ActiveRecord::Base` already has that once
    # turbo-rails is in the bundle):
    #
    #   class Widget < ApplicationRecord
    #     include Crosswire::Streams::Versioned
    #
    #     after_update_commit do
    #       broadcast_versioned_replace_to board, target: dom_id(self),
    #                                              partial: "widgets/widget", locals: { widget: self }
    #     end
    #   end
    #
    #   # app/views/widgets/_widget.html.erb — the SAME partial renders the page and the
    #   # broadcast, so there is exactly one place that ever writes the version:
    #   <div id="<%= dom_id(widget) %>" <%= cw_attrs(crosswire_version_attrs(widget)) %>>
    #
    # Requires optimistic locking (a `lock_version` column — see
    # `ActiveRecord::Locking::Optimistic`). `lock_version` already increments on every
    # successful save, already survives concurrent writers correctly (that is the whole
    # point of optimistic locking), and already exists on plenty of models for a reason
    # having nothing to do with Turbo — reusing it means shipping zero new migrations
    # for a model that already has one, and one obvious column to add
    # (`lock_version:integer`) for a model that does not, rather than crosswire
    # inventing its own bespoke counter.
    module Versioned
      # The version to stamp a broadcast (and the page) with. Delegates to
      # `lock_version` by default; override it on your model if you have a better
      # monotonic source (a dedicated counter column, an external clock) — anything
      # this returns just needs to be comparable with `>` and to only ever increase.
      #
      # @return [Integer]
      # @raise [Crosswire::Error] if this model has no `lock_version` — the message
      #   names the model and the migration that fixes it.
      def crosswire_stream_version
        unless respond_to?(:lock_version)
          raise Crosswire::Error, "#{self.class} has no lock_version — " \
                                   "Crosswire::Streams::Versioned requires optimistic locking. Add it with a " \
                                   "migration (`add_column :your_table, :lock_version, :integer, default: 0, " \
                                   "null: false`), or override crosswire_stream_version on #{self.class} to " \
                                   "return your own monotonically increasing version."
        end

        lock_version
      end

      # Same as `Turbo::Broadcastable#broadcast_replace_to`, but with
      # `action: :versioned_replace` instead of `:replace` — a thin wrapper over
      # `Turbo::StreamsChannel.broadcast_action_to`, not a reimplementation of it.
      # `target:` defaults to `self`, exactly as `broadcast_replace_to` defaults its
      # own target, unless the caller already passed `target:` or `targets:`.
      #
      # Does NOT stamp `data-cw-version` onto the rendered HTML for you — that
      # attribute rides the PARTIAL's root element (`crosswire_version_attrs`, above),
      # which is what makes it identical whether the partial is rendered for the page
      # or for this broadcast. Stamping it here instead, on the `<turbo-stream>`
      # wrapper rather than the payload's root, is exactly the mistake that would
      # break `versioned_replace`'s client-side read of
      # `this.templateContent.firstElementChild.dataset.cwVersion`.
      #
      # @param streamables [Array<Object>] forwarded to `Turbo::StreamsChannel.broadcast_action_to`
      # @param rendering [Hash] forwarded as-is (`partial:`, `locals:`, `html:`, `target:`, …)
      def broadcast_versioned_replace_to(*streamables, **rendering)
        rendering[:target] = self unless rendering.key?(:target) || rendering.key?(:targets)
        return if respond_to?(:suppressed_turbo_broadcasts?) && suppressed_turbo_broadcasts?

        Turbo::StreamsChannel.broadcast_action_to(*streamables, action: :versioned_replace, **rendering)
      end

      # Same as `#broadcast_versioned_replace_to`, but asynchronous — a thin wrapper
      # over `Turbo::StreamsChannel.broadcast_action_later_to`, mirroring
      # `Turbo::Broadcastable#broadcast_replace_later_to` the same way the synchronous
      # method above mirrors `#broadcast_replace_to`.
      #
      # @param streamables [Array<Object>] forwarded to `Turbo::StreamsChannel.broadcast_action_later_to`
      # @param rendering [Hash] forwarded as-is
      def broadcast_versioned_replace_later_to(*streamables, **rendering)
        rendering[:target] = self unless rendering.key?(:target) || rendering.key?(:targets)
        return if respond_to?(:suppressed_turbo_broadcasts?) && suppressed_turbo_broadcasts?

        Turbo::StreamsChannel.broadcast_action_later_to(*streamables, action: :versioned_replace, **rendering)
      end
    end
  end
end
