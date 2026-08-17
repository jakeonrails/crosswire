# frozen_string_literal: true

require "crosswire/builder"

module Crosswire
  # The only helper crosswire mixes into every view — the entry point onto the whole
  # component vocabulary (docs/DECISIONS.md D8).
  #
  #   cw.disclosure "Shipping details", id: "shipping" do ... end
  #
  # `crosswire` is the canonical name; `cw` is the shipped alias — mirroring Rails'
  # own `translate`/`t` and `turbo_stream`/`tag.` idioms. Both return the SAME memoized
  # `Crosswire::Builder` for the life of the view, so `cw.equal?(crosswire)` is true
  # within one render.
  #
  # `require "crosswire/builder"` lives at the top of THIS file, not `lib/crosswire.rb`,
  # deliberately: `Crosswire::Builder`'s class body includes every per-component helper
  # module (`Crosswire::DisclosureHelper` and friends, living under `app/helpers/`), and
  # those constants are only resolvable once Zeitwerk has actually set up the engine's
  # autoload paths. `lib/crosswire.rb` is required during `Bundler.require`, well BEFORE
  # that happens; this file, being itself an `app/helpers/` file, is only ever loaded by
  # Zeitwerk autoload — triggered by the `include Crosswire::FacadeHelper` call in
  # `lib/crosswire/engine.rb`'s `crosswire.helpers` initializer, which runs during
  # `Rails::Application#initialize!`, safely after autoloading is live.
  module FacadeHelper
    def crosswire
      @_crosswire_builder ||= Crosswire::Builder.new(self)
    end
    alias_method :cw, :crosswire
  end
end
