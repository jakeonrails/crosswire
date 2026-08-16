# frozen_string_literal: true

module Crosswire
  VERSION = "0.1.0.alpha"

  # Bumped when a shipped partial's contract changes — i.e. when the markup a
  # controller or presenter expects is no longer what an older ejected copy provides.
  # ShadowCheck compares this against the `<%# crosswire:contract vN %>` marker in any
  # partial the consumer has shadowed. See docs/DECISIONS.md D5/D6.
  CONTRACT_VERSION = 1
end
