# frozen_string_literal: true

# crosswire adds exactly one helper globally (`cw_attrs` / `cw_presenter`, via the
# engine's `crosswire.helpers` initializer). Everything else is opt-in per component,
# which is what this include list is demonstrating.
class ApplicationController < ActionController::Base
  helper Crosswire::AutosubmitHelper
  helper Crosswire::ClipboardHelper
  helper Crosswire::ConfirmHelper
  helper Crosswire::DialogHelper
  helper Crosswire::DisclosureHelper
  helper Crosswire::DismissHelper
  helper Crosswire::FocusTrapHelper
  helper Crosswire::IntersectionHelper
  helper Crosswire::PersistHelper
  helper Crosswire::TransitionHelper
end
