# frozen_string_literal: true

# Shared machinery between bin/build_site.rb and bin/build_gallery.rb (ui-tier-spec.md
# §9) — extracted rather than duplicated, so the two build scripts cannot quietly
# re-derive the same few string primitives differently and drift. Every method here
# was lifted verbatim out of bin/build_site.rb; bin/build_site.rb's own output stays
# byte-for-byte identical after the move (verified by diff, not just by inspection).
module SiteBundle
  # Strip ES module syntax so a controller's real source can be inlined into a single
  # flat <script type="module"> block with no bundler — see bin/build_site.rb's own
  # header comment for why DEMOED controllers are inlined at all.
  def self.strip_module_syntax(source)
    source
      .gsub(/^import .*$/, "")               # inlined, so nothing to import
      .gsub(/^export \{[^}]*\};?\s*$/m, "")  # Stimulus' trailing export block
      .gsub(/^export default class/, "class") # our controllers
      .gsub(/^export /, "")
  end

  def self.class_name_for(name)
    "#{name.split("_").map(&:capitalize).join}Controller"
  end

  # Replace the FIRST occurrence of `marker` in `html` with `replacement`, verbatim.
  #
  # BLOCK FORM IS MANDATORY HERE. `String#sub` with a *string* replacement interprets
  # backreferences in that replacement — `\0`–`\9`, `\&`, `` \` ``, `\'`, `\\` and `\+`.
  #
  # This bit hard, once. Stimulus's own action-descriptor regex contains `\+`:
  #
  #   /^(?:(?:([^.]+?)\+)?(.+?)…/
  #
  # `String#sub` with a plain string second argument read that `\+` as "the last
  # matched group" — our pattern was a plain string with no groups, so it expanded to
  # EMPTY and silently deleted the `\+` from the shipped regex. The optional group
  # then swallowed a character, and every `click->` on the built page was parsed as
  # event `lick`. Nothing threw. The attribute was right, the controller connected,
  # the targets resolved — the whole page was simply inert.
  #
  # The block form returns its value verbatim, with no backreference expansion. Any
  # future caller of this method inherits the fix by construction; there is no string
  # form left to accidentally reach for instead.
  #
  # Silently produces unchanged output (marker absent from `result`, but `replacement`
  # absent too) if `marker` was never present in `html` to begin with — callers that
  # need to distinguish "no-op" from "replaced" must check for that themselves, same
  # as `String#sub` always has.
  def self.inject(html, marker, replacement)
    result = html.sub(marker) { replacement }
    raise "marker #{marker} was not replaced" if result.include?(marker)

    result
  end

  # Guard against `inject` above ever returning wrong, and against any other silent
  # mangling along the way: whatever was inlined must appear in the assembled output
  # byte for byte, or this raises naming what didn't survive.
  def self.assert_present!(haystack, needle, label)
    raise "FATAL: #{label} does not match its source — injection corrupted it" unless haystack.include?(needle)
  end
end
