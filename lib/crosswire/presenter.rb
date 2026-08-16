# frozen_string_literal: true

require "crosswire/attributes"

module Crosswire
  # Base class for attribute presenters.
  #
  # A presenter computes the attribute hashes a component's elements need. It owns
  # NO markup and takes NO view context — it is a plain Ruby object that returns
  # plain hashes. That constraint is deliberate and load-bearing:
  #
  #   * it makes every renderer (ERB partial, ViewComponent, Phlex) a thin wrapper
  #     with zero logic, so they cannot drift from each other
  #   * it makes the whole component library unit-testable without booting Rails
  #   * it is what lets a consumer drop to raw markup and still get correct wiring
  #
  # See docs/DECISIONS.md D5.
  #
  # Subclasses expose one public `*_attrs` method per element:
  #
  #   class Disclosure < Presenter
  #     def initialize(open: false, **overrides)
  #       @open, @overrides = open, overrides
  #     end
  #
  #     def root_attrs = merge(controller_attrs, values(open: @open), @overrides)
  #     def trigger_attrs = merge(target(:trigger), action("click->toggle"))
  #   end
  #
  # The Stimulus identifier is derived from the class name, so Ruby and JS cannot
  # drift — the convention lifted from Solidus's `stimulus_id` (see notes/17).
  class Presenter
    class << self
      # `Crosswire::Presenters::FocusTrap` => `cw--focus-trap`
      def identifier
        @identifier ||= "cw--#{component_name}"
      end

      def component_name
        @component_name ||= name.split("::").last
                                .gsub(/([a-z\d])([A-Z])/, '\1-\2')
                                .downcase
      end
    end

    # Every presenter accepts arbitrary caller attributes and merges them last, so a
    # consumer can always add their own controller, classes or data to the root
    # element without losing ours.
    def initialize(**overrides)
      @overrides = overrides
    end

    private

    attr_reader :overrides

    def identifier = self.class.identifier

    def merge(*sources) = Attributes.merge(*sources)

    # `data-controller="cw--disclosure"`
    def controller_attrs(*extra)
      { "data-controller" => Attributes.union(identifier, *extra) }
    end

    # `target(:panel)` => `data-cw--disclosure-target="panel"`
    def target(name)
      { "data-#{identifier}-target" => name.to_s }
    end

    # `action("click->toggle", "keydown.esc->close")`
    #   => `data-action="click->cw--disclosure#toggle keydown.esc->cw--disclosure#close"`
    #
    # A spec containing `#` is passed through untouched, so a presenter can also wire
    # an action on a *different* controller when it genuinely needs to.
    def action(*specs)
      { "data-action" => specs.flatten.map { |spec| expand_action(spec) }.join(" ") }
    end

    # `values(open: false, delay: 200)`
    #   => `data-cw--disclosure-open-value="false"`, `...-delay-value="200"`
    #
    # Values are the public API of a reusable controller — the mechanism by which one
    # generic controller serves many features.
    def values(pairs)
      pairs.each_with_object({}) do |(name, value), out|
        next if value.nil?

        out["data-#{identifier}-#{dasherize(name)}-value"] = serialize_value(value)
      end
    end

    # `classes(open: "is-open")` => `data-cw--disclosure-open-class="is-open"`
    #
    # The CSS Classes API is why our controllers carry no design-system opinions and
    # work under Tailwind, plain CSS, or a consumer's own system.
    #
    # NOTE for controller authors: Stimulus's `this.fooClass` THROWS when the attribute
    # is absent — there is no default mechanism. Every crosswire controller must guard
    # with `hasFooClass`. This is the most likely way a component breaks for a consumer
    # who did not pass a class. See notes/17.
    def classes(pairs)
      pairs.each_with_object({}) do |(name, value), out|
        next if value.nil?

        out["data-#{identifier}-#{dasherize(name)}-class"] = Attributes.union(value)
      end
    end

    # Namespaced custom event name: `event_name(:opened)` => `cw--disclosure:opened`.
    # Events are the composition primitive — outlets hardcode another controller's
    # identifier, which a distributable component cannot know. See notes/03.
    def event_name(verb) = "#{identifier}:#{dasherize(verb)}"

    def expand_action(spec)
      spec = spec.to_s
      return spec if spec.include?("#")

      event, method = spec.split("->", 2)
      method ? "#{event}->#{identifier}##{method}" : "#{identifier}##{event}"
    end

    def serialize_value(value)
      case value
      when Hash, Array then JSON.generate(value)
      when true, false then value.to_s
      else value
      end
    end

    def dasherize(name) = name.to_s.tr("_", "-")
  end
end
