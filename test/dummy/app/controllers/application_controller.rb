# frozen_string_literal: true

# crosswire adds exactly one helper globally (`cw_attrs` / `cw_presenter`, via the
# engine's `crosswire.helpers` initializer). Everything else is opt-in per component,
# which is what this include list is demonstrating.
#
# Derived from `Crosswire.component_names` — the engine's own registry
# (lib/crosswire.rb) — rather than hardcoded one `helper` line per component. A
# hardcoded list silently rots the moment a new component ships: it would still boot
# fine, it would just leave the new component's helper uncallable from this app,
# which is exactly what `HelperContractTest#test_every_helper_method_is_callable_from_a_host_app_controller`
# exists to catch. Looping the registry means that class of failure cannot recur.
class ApplicationController < ActionController::Base
  Crosswire.component_names.each do |name|
    helper Crosswire.const_get(:"#{name.camelize}Helper")
  end
end
