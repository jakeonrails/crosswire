# frozen_string_literal: true

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../../Gemfile", __dir__)

require "bundler/setup"

# The gem under test is loaded straight from source, never from an installed copy,
# so `bin/rails s` here is always exercising the working tree.
$LOAD_PATH.unshift File.expand_path("../../../lib", __dir__)
