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

  # GET target for the `loading`/`fallback` Lookbook previews — see routes.rb.
  # Sleeps briefly so a real fetch is slow enough to observe cw--loading's
  # anti-flicker delay and cw--fallback's "loading" state, then renders a
  # <turbo-frame> whose id matches whatever the requesting frame/form asked for
  # (?id=), which is how Turbo knows to match the response into it.
  def survivability_demo_slow
    sleep 1.5
    render partial: "demo/survivability_demo_frame",
           locals: {frame_id: params[:id], message: "Loaded at #{Time.current.strftime("%H:%M:%S")}."}
  end

  # GET target for the `fallback` Lookbook preview — see routes.rb. A real 500, so
  # cw--fallback's "failed" state comes from an actual failed response
  # (turbo:before-fetch-response, fetchResponse.succeeded == false), not a
  # simulated one.
  def survivability_demo_fail
    head :internal_server_error
  end
end
