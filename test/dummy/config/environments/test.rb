# frozen_string_literal: true

Rails.application.configure do
  config.enable_reloading = false
  config.eager_load = false
  config.consider_all_requests_local = true
  config.action_controller.perform_caching = false
  config.action_dispatch.show_exceptions = :none
  config.action_controller.allow_forgery_protection = false
  config.assets.quiet = true

  # Previews are part of what the integration suite renders, and lazy loading would
  # hide a broken preview until someone clicked it.
  config.lookbook.lazy_load_previews_and_pages = false
end
