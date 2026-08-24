# frozen_string_literal: true

require "test_helper"

module Crosswire
  module UI
    # WCAG contrast for every token pair a UI component will actually paint text or
    # a focus ring against — spec §7.6. Deliberately no Rails and no CSS parser
    # dependency: this is one file, ~any number of lines, that reads tokens.css (and
    # themes/patchbay.css) as text and does the arithmetic itself. A color choice
    # that fails here is not a style nit; it is inaccessible text shipping by default.
    #
    # Only --cw-color-* custom properties are read — nothing about space/radius/type/
    # shadow/motion/layering tokens is a contrast concern.
    class TokenContrastTest < Minitest::Test
      ROOT = File.expand_path("../../..", __dir__)
      TOKENS_CSS = File.join(ROOT, "app/assets/stylesheets/crosswire/ui/tokens.css")
      PATCHBAY_CSS = File.join(ROOT, "app/assets/stylesheets/crosswire/ui/themes/patchbay.css")

      # 4.5:1 — body text and text-on-role-background pairs (spec §7.6).
      BODY_PAIRS = [
        %i[fg bg],
        %i[fg-muted surface],
        %i[accent-fg accent],
        %i[danger-fg danger],
        %i[success-fg success],
        %i[warning-fg warning],
        %i[info-fg info]
      ].freeze

      # 3:1 — non-text UI element pairs (spec §7.6).
      UI_PAIRS = [
        %i[border-strong bg],
        %i[focus bg]
      ].freeze

      def test_tokens_css_light_pairs_meet_thresholds
        assert_theme_passes(TOKENS_CSS, :light)
      end

      def test_tokens_css_dark_pairs_meet_thresholds
        assert_theme_passes(TOKENS_CSS, :dark)
      end

      def test_patchbay_css_light_pairs_meet_thresholds
        assert_theme_passes(PATCHBAY_CSS, :light)
      end

      def test_patchbay_css_dark_pairs_meet_thresholds
        assert_theme_passes(PATCHBAY_CSS, :dark)
      end

      private

      def assert_theme_passes(path, theme)
        colors = colors_for(path, theme)
        violations = (BODY_PAIRS.map { |pair| [pair, 4.5] } + UI_PAIRS.map { |pair| [pair, 3.0] })
                     .filter_map do |(fg_name, bg_name), threshold|
          fg, bg = colors.fetch(fg_name), colors.fetch(bg_name)
          ratio = contrast_ratio(fg, bg)
          next if ratio >= threshold

          format("--cw-color-%s (%s) vs --cw-color-%s (%s): %.2f:1, need %.1f:1",
                 fg_name, fg, bg_name, bg, ratio, threshold)
        end

        assert_empty violations, <<~MSG
          #{File.basename(path)} (#{theme}) fails WCAG contrast:

          #{violations.map { |v| "  #{v}" }.join("\n")}
        MSG
      end

      # --- CSS reading --------------------------------------------------------------

      def colors_for(path, theme)
        css = File.read(path)
        block = theme == :light ? light_block(css) : dark_block(css)
        properties(block).transform_keys { |k| k.delete_prefix("--cw-color-").to_sym }
      end

      # The plain `:root { ... }` block — deliberately NOT `:root:not(...)` or
      # `:root[...]`, both of which have extra characters between "root" and the
      # opening brace that this anchored, whitespace-only pattern will not match.
      def light_block(css)
        css[/^\s*:root\s*\{(.*?)\n\s*\}/m, 1] or raise "no plain :root {} block found"
      end

      # The static `:root[data-cw-theme="dark"], :root[data-theme="dark"]:not(...)`
      # block — content-identical to the `@media (prefers-color-scheme: dark)` block
      # by construction (see tokens.css's own comment and
      # `ui_contract_audit_test.rb`'s byte-identity check), so either suffices here.
      def dark_block(css)
        css[/:root\[data-cw-theme="dark"\].*?\{(.*?)\n\s*\}/m, 1] or raise "no dark :root[data-cw-theme] block found"
      end

      def properties(block)
        block.scan(/(--cw-color-[\w-]+):\s*([^;]+);/).to_h
      end

      # --- WCAG 2.x relative luminance / contrast ratio ------------------------------

      def contrast_ratio(hex1, hex2)
        l1, l2 = [hex1, hex2].map { |h| relative_luminance(h) }
        lighter, darker = [l1, l2].sort.reverse
        (lighter + 0.05) / (darker + 0.05)
      end

      def relative_luminance(hex)
        r, g, b = hex_to_rgb(hex)
        rl, gl, bl = [r, g, b].map { |c| linearize(c) }
        (0.2126 * rl) + (0.7152 * gl) + (0.0722 * bl)
      end

      def linearize(channel)
        c = channel / 255.0
        c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055)**2.4
      end

      def hex_to_rgb(hex)
        hex = hex.delete("#")
        hex.each_char.each_slice(2).map { |pair| pair.join.to_i(16) }
      end
    end
  end
end
