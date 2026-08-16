# frozen_string_literal: true

# Renders every shipped helper and every shipped partial. The integration suite hits
# these actions, so a helper that raises under a real render fails the build here
# rather than in a consumer's app.
class DemoController < ApplicationController
  def index; end
  def behaviours; end
  def layer0; end
  def overrides; end
end
