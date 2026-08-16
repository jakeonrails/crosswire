# frozen_string_literal: true

# Deliberately does NOT boot Rails. The presenter core is plain Ruby, and this test
# suite failing to load Rails is the guarantee that it stays that way.
# See docs/DECISIONS.md D5.

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "crosswire"
require "minitest/autorun"
