# frozen_string_literal: true

Rails.application.routes.draw do
  root "demo#index"

  get "/behaviours", to: "demo#behaviours"
  get "/layer0",     to: "demo#layer0"
  get "/overrides",  to: "demo#overrides"

  # A real PATCH target for the `sortable` Lookbook preview, so its keyboard
  # move-up/move-down path exercises the actual persist round trip (fetch, success
  # event, no revert) instead of always hitting the failure/revert branch against a
  # 404. Lives here rather than in `crosswire`'s own routes because D2 is explicit
  # that the gem ships none of its own — this is the consumer-app endpoint a real
  # host would write.
  patch "/sortable_demo", to: "demo#sortable_demo"

  # crosswire ships no routes of its own (D2 — the consumer writes their own endpoints),
  # but mounting it proves the engine is a well-formed mountable engine.
  mount Crosswire::Engine => "/crosswire"

  mount Lookbook::Engine, at: "/lookbook"
end
