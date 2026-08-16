# frozen_string_literal: true

# Renders every shipped helper and every shipped partial. The integration suite hits
# these actions, so a helper that raises under a real render fails the build here
# rather than in a consumer's app.
class DemoController < ApplicationController
  # Lookbook's own preview rendering pipeline never establishes a session for the
  # pages it serves (`/lookbook/preview/...` carries no `Set-Cookie` at all — verified
  # directly, not assumed), so a CSRF token embedded via `csrf_meta_tags` in
  # `crosswire_preview.html.erb` can never be validated against anything: there is no
  # session-side secret for it to be checked against, regardless of the token being
  # present and correctly formed. That is a property of Lookbook's preview controller,
  # not of `cw--sortable`'s own fetch, which sends the token exactly as documented.
  # Skipped here, and only here, because this action exists solely to give the
  # `sortable` Lookbook preview something real to PATCH against — it is demo
  # scaffolding with no user data behind it, not a production endpoint.
  skip_before_action :verify_authenticity_token, only: :sortable_demo, raise: false

  def index; end
  def behaviours; end
  def layer0; end
  def overrides; end

  # PATCH target for the `sortable` Lookbook preview — see routes.rb. Accepts
  # whatever order was posted and simply acknowledges it; this dummy app has no
  # records to actually persist a position column onto.
  def sortable_demo
    head :ok
  end
end
