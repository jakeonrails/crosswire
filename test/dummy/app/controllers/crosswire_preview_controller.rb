# frozen_string_literal: true

# Lookbook's default preview controller is a bare `Rails::ApplicationController`, so it
# has neither the host app's helpers nor any engine's view paths. For a library whose
# headline API *is* a helper (`cw.disclosure`), that means previews cannot call the
# thing they are meant to be documenting — Lookbook issue #745, still open.
#
# The whole fix is `config.lookbook.preview_controller` plus this file. crosswire's
# install generator should write both for consumers.
#
# Two distinct problems are being solved here:
#
#   1. `helper Crosswire::AttributesHelper` / `Crosswire::FacadeHelper` — makes
#      `cw`/`crosswire` (and therefore every component, via the builder) and `cw_attrs`
#      callable from preview templates. As of D8, these are the ONLY two helper modules
#      that exist to include — every per-component helper module is included into
#      `Crosswire::Builder` itself (lib/crosswire/builder.rb), not into any view or
#      controller, so there is no longer a `Crosswire.component_names.each { helper ... }`
#      loop to maintain here.
#   2. `append_view_path Crosswire::Engine.root.join("app/views")` — Lookbook prepends
#      only `Rails.root/app/views` and its own preview paths, so without this the
#      shipped `crosswire/_disclosure` partial is simply not on the lookup path and
#      `cw.disclosure` raises `MissingTemplate` inside a preview.
#
# Appending (not prepending) keeps a consumer's shadowed copy winning inside Lookbook,
# which is the behaviour D5/D6 want a preview to show.
class CrosswirePreviewController < Lookbook::PreviewController
  helper Crosswire::AttributesHelper
  helper Crosswire::FacadeHelper

  append_view_path Rails.root.join("app/views")
  append_view_path Crosswire::Engine.root.join("app/views")
end
