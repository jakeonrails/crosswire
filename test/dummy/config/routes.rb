# frozen_string_literal: true

Rails.application.routes.draw do
  root "demo#index"

  get "/behaviours", to: "demo#behaviours"
  get "/layer0",     to: "demo#layer0"
  get "/overrides",  to: "demo#overrides"

  # crosswire ships no routes of its own (D2 — the consumer writes their own endpoints),
  # but mounting it proves the engine is a well-formed mountable engine.
  mount Crosswire::Engine => "/crosswire"

  mount Lookbook::Engine, at: "/lookbook"
end
