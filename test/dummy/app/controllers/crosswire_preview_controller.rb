# frozen_string_literal: true

# Lookbook's default preview controller is a bare `Rails::ApplicationController`, so it
# has neither the host app's helpers nor any engine's view paths. For a library whose
# headline API *is* a helper (`crosswire_disclosure`), that means previews cannot call
# the thing they are meant to be documenting — Lookbook issue #745, still open.
#
# The whole fix is `config.lookbook.preview_controller` plus this file. crosswire's
# install generator should write both for consumers.
#
# Two distinct problems are being solved here:
#
#   1. `helper Crosswire::…Helper` — makes `crosswire_disclosure` and friends callable
#      from preview templates. (`cw_attrs` arrives for free: the engine includes
#      `Crosswire::AttributesHelper` into ActionView globally.)
#   2. `append_view_path Crosswire::Engine.root.join("app/views")` — Lookbook prepends
#      only `Rails.root/app/views` and its own preview paths, so without this the
#      shipped `crosswire/_disclosure` partial is simply not on the lookup path and
#      `crosswire_disclosure` raises `MissingTemplate` inside a preview.
#
# Appending (not prepending) keeps a consumer's shadowed copy winning inside Lookbook,
# which is the behaviour D5/D6 want a preview to show.
#
# The helper list is derived from `Crosswire.component_names` — the engine's own
# registry (lib/crosswire.rb) — instead of one hardcoded `helper` line per component,
# for the same reason `ApplicationController` does it this way: a hardcoded list would
# leave every newly shipped component's preview unable to call its own helper, which
# `LookbookTest#test_engine_helpers_are_callable_in_previews` exists to catch.
class CrosswirePreviewController < Lookbook::PreviewController
  helper Crosswire::AttributesHelper

  Crosswire.component_names.each do |name|
    helper Crosswire.const_get(:"#{name.camelize}Helper")
  end

  # `Crosswire::StreamsHelper` names no component — it wraps `turbo_stream_from` for
  # `Crosswire::AuthorizedStreamChannel`, with no controller/presenter pair of its own —
  # so it can never be found by looping `Crosswire.component_names` above. Added by
  # hand, same as `test/crosswire/integration_test_runner.rb`'s `HelperCase` does.
  helper Crosswire::StreamsHelper

  append_view_path Rails.root.join("app/views")
  append_view_path Crosswire::Engine.root.join("app/views")
end
