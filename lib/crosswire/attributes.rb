# frozen_string_literal: true

module Crosswire
  # Merge HTML attribute hashes without clobbering the ones that must accumulate.
  #
  # Rails has no merge-don't-clobber facility (`form_with` does a shallow `merge!`),
  # which is why every production codebase that pairs Stimulus controllers with ERB
  # helpers hand-patched this differently. See research/notes/17-helper-layer-design.md.
  #
  # Deliberately pure Ruby — no ActionView. Presenters must stay usable without Rails,
  # so the token union is implemented here rather than borrowed from `token_list`.
  # Escaping is the renderer's job, not ours.
  #
  #   Attributes.merge(
  #     { data: { controller: "cw--disclosure" } },
  #     { data: { controller: "analytics", action: "click->analytics#track" } }
  #   )
  #   # => { "data-controller" => "cw--disclosure analytics",
  #   #      "data-action"     => "click->analytics#track" }
  #
  # Rules:
  #   * `class`, `data-controller` and `data-action` UNION (deduped, order preserved)
  #   * every other key is last-wins
  #   * `data:` and `aria:` nested hashes flatten to dashed keys
  #   * an explicit `nil` DELETES the key
  #   * a trailing `!` on a key forces replacement instead of union — the escape hatch
  #     lifted from seanpdoyle/stimulus_aria_widgets (see notes/19)
  #
  # Idempotent: merging a result back into itself is a no-op. That is what makes it
  # safe to apply at every layer of the helper stack rather than exactly once.
  module Attributes
    # The only attributes where a caller's value must be added to ours, never replace it.
    UNION_KEYS = %w[class data-controller data-action].freeze

    # Keys whose Array values should space-join rather than fall through to Rails'
    # JSON encoding. Rails only special-cases `class` and `aria`, so
    # `data: { controller: ["a", "b"] }` silently renders as JSON — a real trap.
    ARRAY_JOIN_KEYS = (UNION_KEYS + %w[aria-labelledby aria-describedby aria-owns aria-controls]).freeze

    class << self
      # @param sources [Array<Hash, nil>] attribute hashes, later ones winning
      # @return [Hash{String => Object}] flat, dashed-key attributes
      def merge(*sources)
        sources.compact.reduce({}) do |result, source|
          flatten(source).each do |key, value|
            force = key.end_with?("!")
            key = key.delete_suffix("!")

            if value.nil?
              result.delete(key)
            elsif force || !UNION_KEYS.include?(key)
              result[key] = value
            else
              result[key] = union(result[key], value)
            end
          end
          result
        end
      end

      # Union two token strings, preserving first-seen order and deduping.
      # Deduping is what makes `merge` idempotent.
      def union(*values)
        values.flat_map { |value| tokenize(value) }.uniq.join(" ")
      end

      private

      def tokenize(value)
        case value
        when nil    then []
        when Array  then value.flat_map { |v| tokenize(v) }
        else value.to_s.split(/\s+/).reject(&:empty?)
        end
      end

      # Flatten one level of `data:` / `aria:` nesting into dashed string keys.
      def flatten(source)
        source.each_with_object({}) do |(key, value), out|
          name = key.to_s

          if value.is_a?(Hash) && %w[data aria].include?(name.delete_suffix("!"))
            value.each do |nested_key, nested_value|
              full = "#{name.delete_suffix("!")}-#{dasherize(nested_key)}"
              full += "!" if name.end_with?("!") || nested_key.to_s.end_with?("!")
              out[full.sub("!-", "-")] = cast(full, nested_value)
            end
          else
            out[dasherize_preserving_bang(name)] = cast(name, value)
          end
        end
      end

      def cast(key, value)
        return value unless value.is_a?(Array)
        return value.join(" ") if ARRAY_JOIN_KEYS.include?(key.delete_suffix("!"))

        value
      end

      # `cw__disclosure_target` => `cw--disclosure-target`.
      # Rails dasherizes `_` to `-` in data keys, so `__` becomes `--`, which is what
      # lets a namespaced Stimulus identifier be written in plain Ruby hash syntax.
      def dasherize(key)
        key.to_s.delete_suffix("!").tr("_", "-")
      end

      def dasherize_preserving_bang(key)
        bang = key.end_with?("!")
        "#{dasherize(key)}#{"!" if bang}"
      end
    end
  end
end
