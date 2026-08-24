# frozen_string_literal: true

module Crosswire
  module UI
    # Declarative class-string builder for a UI component's variants — button's
    # primary/secondary/ghost/danger/link, a future badge/card's tone, and so on.
    #
    # Deliberately not a CVA port and no twMerge: crosswire's shipped CSS is semantic
    # classes (`cw-button--primary`), not Tailwind utilities, so there is nothing at
    # this layer to dedupe or conflict-resolve. `Crosswire::Attributes.merge` remains
    # the ONLY merge semantics anywhere in this codebase — see hotwire_combobox's
    # dual-merge bug (research/notes/17 §1.3), cited in the UI-tier spec §3 as exactly
    # the trap a second merge implementation here would reopen.
    #
    #   class Button < Crosswire::UI::Component
    #     extend Crosswire::UI::Variants
    #
    #     base "cw-button"
    #     variant :variant, { primary: "cw-button--primary", secondary: nil,
    #                          ghost: "cw-button--ghost", danger: "cw-button--danger",
    #                          link: "cw-button--link" }, default: :secondary
    #     variant :size, { sm: "cw-button--sm", md: nil, lg: "cw-button--lg" }, default: :md
    #     boolean :block, "cw-button--block"
    #   end
    #
    #   Button.variant_class(variant: :primary, size: :md, block: true)
    #     # => "cw-button cw-button--primary cw-button--block"
    #
    # Rules (spec §3), each load-bearing:
    #   1. class order is FIXED: base, then every declared variant/boolean in
    #      declaration order, then the caller's own `class:` — added later, by
    #      `Attributes.merge`, never by this file.
    #   2. a `nil` mapped value means the base class already expresses that state —
    #      emit nothing for it, not an empty string that would leave a stray space.
    #   3. an unknown value RAISES ArgumentError naming the valid values, rather than
    #      silently emitting no class — a typo'd variant should fail loudly in dev/test,
    #      not ship a half-styled component to production.
    #   4. `.variants` introspects the whole declared table — feeds the gallery's props
    #      table and registry.json (spec §4/§9), so it must never require instantiating
    #      the component to learn its variants.
    #   5. no twMerge/cx of any kind (rule 5 above).
    module Variants
      Declaration = Struct.new(:name, :map, :default, keyword_init: true)

      # `base "cw-button"` sets it; `base` with no argument reads it back.
      def base(class_name = nil)
        @base_class = class_name if class_name
        @base_class
      end

      # `variant :variant, { primary: "cw-button--primary", secondary: nil }, default: :secondary`
      def variant(name, map, default:)
        (@variant_declarations ||= []) << Declaration.new(name: name, map: map, default: default)
      end

      # Sugar for the common two-value case: `boolean :block, "cw-button--block"`
      # is exactly `variant :block, { true => "...", false => nil }, default: false`.
      def boolean(name, class_name, default: false)
        variant(name, { true => class_name, false => nil }, default: default)
      end

      def variant_declarations = @variant_declarations || []

      # `{ variant: { values: [:primary, :secondary, ...], default: :secondary }, ... }`
      def variants
        variant_declarations.each_with_object({}) do |d, out|
          out[d.name] = { values: d.map.keys, default: d.default }
        end
      end

      # Compute the fixed-order class string for one instance's variant values.
      # `values` is a Hash of variant name => value; an absent key falls back to that
      # variant's declared default, exactly like a keyword argument would.
      def variant_class(values)
        variant_declarations.each_with_object([base]) do |d, classes|
          value = values.fetch(d.name, d.default)

          unless d.map.key?(value)
            raise ArgumentError, "#{self}: unknown #{d.name.inspect} value #{value.inspect} " \
                                  "— valid values: #{d.map.keys.map(&:inspect).join(", ")}"
          end

          classes << d.map[value] if d.map[value]
        end.compact.join(" ")
      end
    end
  end
end
