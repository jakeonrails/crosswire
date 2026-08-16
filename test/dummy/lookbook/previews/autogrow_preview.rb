# frozen_string_literal: true

# **What it is.** Size a `<textarea>` to its content. A *behaviour* — no markup, no
# partial — that decorates a `<textarea>` you already have.
#
# **Lead with the truth: on every current browser, this component does nothing, and the
# CSS below is doing all of the visible growth.** `field-sizing: content` is Baseline CSS
# (Chrome/Edge 123+, Firefox 152+, Safari 26.2+ — every current-generation engine) and
# grows a textarea to fit its content with zero JavaScript:
#
#   textarea {
#     field-sizing: content;
#     min-height: 3lh;   /* don't collapse to one line when empty */
#     max-height: 20lh;  /* then it scrolls */
#     resize: vertical;  /* still let the user override */
#   }
#
# `cw--autogrow`'s own `connect()` checks `CSS.supports("field-sizing", "content")`
# *first*, before touching the DOM at all, and no-ops entirely when it is true — which it
# is here, in whatever browser is rendering this preview. Reach for the JS controller
# only when your support matrix genuinely still includes engines predating those
# versions. Ship both together and it stays safe either way: on a modern engine the CSS
# alone does the work; on an old one the controller measures `scrollHeight` on `input`
# and on `connect()` (the latter covers a Turbo cache restore, whose snapshot has no
# live layout baked in).
#
# **This component is SUNSETTING** (research/notes/08) — plan to delete it, and the
# `data-controller="cw--autogrow"` attribute referencing it, once your support matrix no
# longer needs it.
#
# **Rule 0** is the whole story here (R9) — see above.
class AutogrowPreview < Lookbook::Preview
  # @param max_rows number "Caps growth at this many rows (0 = unbounded); optional"
  def default(max_rows: 6)
    render_with_template(template: "autogrow_preview/default", locals: {max_rows: max_rows.to_i.zero? ? nil : max_rows})
  end
end
