# frozen_string_literal: true

# The real integration suite: every helper rendered, every partial rendered, the engine's
# initializers observed after they have actually run, ShadowCheck exercised against real
# boots, and every Lookbook preview fetched over HTTP.
#
# This file is NOT named `*_test.rb` on purpose and is never `require`d in-process.
# `integration_test.rb` runs it as its own child process — see the comment there for why
# (short version: `test/test_helper.rb` guarantees the presenter suite never sees Rails,
# and booting Rails anywhere in that shared process would break every sibling's
# `refute defined?(::Rails)`).
#
# Run it directly and it behaves as an ordinary, self-contained Minitest suite:
#
#   bundle exec ruby test/crosswire/integration_test_runner.rb

ENV["RAILS_ENV"] = "test"

require File.expand_path("../dummy/config/environment", __dir__)
require "rails/test_help"
require "minitest/autorun"
require "nokogiri"

module CrosswireIntegration
  # Assertions about *parsed* HTML rather than raw markup.
  #
  # This matters more than it looks. `tag.attributes` HTML-escapes attribute values, so a
  # Stimulus action descriptor goes out on the wire as
  # `data-action="click-&gt;cw--disclosure#toggle"`. That is correct, valid HTML — the
  # parser turns `&gt;` back into `>` before Stimulus ever sees it — but a suite that
  # string-matched `click->` on the raw body would report a bug that does not exist, and a
  # suite that string-matched `click-&gt;` would be asserting on an encoding detail rather
  # than on behaviour. So: assert on the DOM, and pin the escaping itself in exactly one
  # place (`Layer0Test#test_action_arrow_is_escaped_on_the_wire_and_decoded_by_the_parser`).
  module Dom
    def dom(html)
      Nokogiri::HTML5.fragment(html.to_s)
    end

    def node(html, selector)
      found = dom(html).at_css(selector)
      found || flunk("no element matching #{selector.inspect} in:\n\n#{html}")
    end

    # Parse a bare attribute string (what `cw_attrs` returns) by hanging it on an element.
    def attrs(fragment)
      node("<i #{fragment}></i>", "i")
    end

    def tokens(node, attribute)
      node[attribute].to_s.split(/\s+/)
    end

    def assert_token(expected, node, attribute)
      assert_includes tokens(node, attribute), expected,
                      "expected #{attribute}=#{node[attribute].inspect} to contain #{expected.inspect}"
    end
  end

  # Every helper module, mixed into one view context. Mirrors what a consumer's
  # ApplicationController does.
  #
  # Derived from `Crosswire.component_names` rather than one hardcoded `helper` line
  # per component, same reasoning as `ApplicationController`/`CrosswirePreviewController`
  # in the dummy app: a hardcoded list here would silently leave a newly shipped
  # component's helper uncallable from every test in this file that renders through
  # `HelperCase`, rather than failing loudly.
  class HelperCase < ActionView::TestCase
    include Dom

    helper Crosswire::AttributesHelper
    Crosswire.component_names.each do |name|
      helper Crosswire.const_get(:"#{name.camelize}Helper")
    end
  end

  # ---------------------------------------------------------------------------------
  # The helper half of the component contract. `contract_audit_test.rb` already machine-
  # checks controllers, presenters and partials without Rails; helpers cannot be checked
  # there, because they are `app/` constants that only exist once an engine is loaded.
  # This is the test that would have caught `Crosswire::DismissHelper` simply not
  # existing — `dismiss` is a shipped component and one of the two reference
  # implementations, and its helper file was missing.
  # ---------------------------------------------------------------------------------
  class HelperContractTest < ActiveSupport::TestCase
    def test_every_component_ships_a_helper_module
      missing = Crosswire.component_names.reject do |name|
        Crosswire.const_defined?(:"#{name.camelize}Helper")
      end

      assert_empty missing, "components with no Crosswire::<Name>Helper: #{missing.join(", ")}"
    end

    def test_every_helper_module_exposes_at_least_one_public_helper_method
      Crosswire.component_names.each do |name|
        mod = Crosswire.const_get(:"#{name.camelize}Helper")
        methods = mod.public_instance_methods(false)

        refute_empty methods, "#{mod} defines no helper methods"
        assert methods.all? { |m| m.to_s.start_with?("crosswire_#{name}") },
               "#{mod} methods #{methods.inspect} do not follow crosswire_#{name}*"
      end
    end

    def test_every_helper_method_is_callable_from_a_host_app_controller
      helpers = ApplicationController.helpers

      Crosswire.component_names.each do |name|
        Crosswire.const_get(:"#{name.camelize}Helper").public_instance_methods(false).each do |method|
          assert_respond_to helpers, method,
                            "#{method} is not available after `helper Crosswire::#{name.camelize}Helper`"
        end
      end
    end
  end

  # ---------------------------------------------------------------------------------
  # Layer 0 — cw_attrs / cw_presenter
  # ---------------------------------------------------------------------------------
  class Layer0Test < HelperCase
    def test_cw_attrs_renders_flat_dashed_attributes
      el = attrs(view.cw_attrs(Crosswire::Presenters::Disclosure.new(id: "faq").root_attrs))

      assert_equal "cw--disclosure", el["data-controller"]
      assert_equal "false", el["data-cw--disclosure-open-value"]
      assert_equal "faq", el["id"]
    end

    def test_cw_attrs_merges_several_sources_left_to_right
      el = attrs(view.cw_attrs({data: {controller: "cw--dismiss"}},
                               {data: {controller: "cw--transition"}},
                               class: "flash"))

      assert_equal %w[cw--dismiss cw--transition], tokens(el, "data-controller")
      assert_equal "flash", el["class"]
    end

    def test_cw_attrs_returns_html_safe_output
      assert_predicate view.cw_attrs(class: "a"), :html_safe?
    end

    def test_cw_attrs_escapes_a_value_containing_markup
      el = attrs(view.cw_attrs("data-x" => %(</i><script>alert(1)</script>)))

      assert_equal %(</i><script>alert(1)</script>), el["data-x"]
      refute_includes view.cw_attrs("data-x" => "<script>").to_s, "<script>"
    end

    # The research note flagged this: `->` goes out as `-&gt;`. Assert what actually
    # happens rather than what would be convenient.
    def test_action_arrow_is_escaped_on_the_wire_and_decoded_by_the_parser
      raw = view.cw_attrs(Crosswire::Presenters::Disclosure.new(id: "faq").trigger_attrs).to_s

      assert_includes raw, "click-&gt;cw--disclosure#toggle",
                      "expected the raw attribute value to be HTML-escaped"
      refute_includes raw, "click->cw--disclosure#toggle"

      assert_equal "click->cw--disclosure#toggle", attrs(raw)["data-action"],
                   "expected an HTML parser to decode it back to the descriptor Stimulus reads"
    end

    def test_cw_attrs_with_no_attributes_renders_nothing
      # `Attributes.merge` documents an explicit nil as DELETING a key, so an
      # all-nil call legitimately produces an empty hash — and must not raise.
      assert_equal "", view.cw_attrs.to_s
      assert_equal "", view.cw_attrs({}).to_s
      assert_equal "", view.cw_attrs(class: nil).to_s
    end

    def test_cw_presenter_builds_by_name
      assert_instance_of Crosswire::Presenters::Disclosure, view.cw_presenter(:disclosure, id: "x")
      assert_instance_of Crosswire::Presenters::FocusTrap, view.cw_presenter(:focus_trap)
      assert_instance_of Crosswire::Presenters::FocusTrap, view.cw_presenter("focus_trap")
    end

    def test_cw_presenter_rejects_an_unknown_component_by_name
      error = assert_raises(ArgumentError) { view.cw_presenter(:accordion) }

      assert_match(/accordion/, error.message)
      assert_match(/disclosure/, error.message)
    end

    # Every presenter with a REQUIRED keyword (no default in its `initialize`) needs an
    # entry here, or `cw_presenter(name)` below raises `ArgumentError: missing keyword`.
    #
    # Deliberately an explicit fixture map, not a generic `rescue ArgumentError` around
    # the construction below. A rescue would make this test degrade gracefully — and
    # silently — the moment a ninth, tenth, eleventh component shipped a new required
    # keyword: it would swallow the error and the test would keep passing having
    # constructed nothing for that component, defeating the point of "covers every
    # shipped component." An explicit map fails LOUDLY (a plain missing-keyword
    # `ArgumentError`) instead, forcing a human to add a line here and — more
    # importantly — to decide what a representative fixture value looks like for that
    # component (a real id, a real CSS selector, a real key spec), which is a judgment
    # call this test should never make up on a component's behalf.
    REQUIRED_ARGS = {
      "disclosure" => {id: "probe"},
      "dialog" => {id: "probe"},
      "persist" => {key: "probe"},
      "hotkey" => {key: "probe"},
      "timeout" => {delay: 1000},
      "sync" => {target: "#probe"},
      "tabs" => {id: "probe", selected: "one"},
      "popover" => {id: "probe"}
    }.freeze

    def test_cw_presenter_covers_every_shipped_component
      Crosswire.component_names.each do |name|
        assert_kind_of Crosswire::Presenter, view.cw_presenter(name, **REQUIRED_ARGS.fetch(name, {}))
      end
    end

    def test_layer0_wires_a_completely_different_element_structure
      html = view.render(template: "demo/layer0")
      root = node(html, "#layer0-disclosure details")

      assert_equal "cw--disclosure", root["data-controller"]
      assert_equal "trigger", node(html, "#layer0-disclosure summary")["data-cw--disclosure-target"]
      assert_equal "panel", node(html, "#layer0-disclosure details > div")["data-cw--disclosure-target"]
    end
  end

  # ---------------------------------------------------------------------------------
  # Widgets — the three components that own markup
  # ---------------------------------------------------------------------------------
  class DisclosureRenderTest < HelperCase
    def render_default(**options, &block)
      block ||= proc { "<p>panel body</p>".html_safe }
      view.crosswire_disclosure("Shipping details", **{id: "faq"}.merge(options), &block)
    end

    def test_partial_renders_the_full_widget
      html = render_default

      assert_equal "cw--disclosure", node(html, "div")["data-controller"]
      assert_equal "trigger", node(html, "button")["data-cw--disclosure-target"]
      assert_equal "panel", node(html, "div div")["data-cw--disclosure-target"]
      assert_includes html, "panel body"
    end

    def test_partial_carries_every_aria_guarantee_the_presenter_promises
      html = render_default
      trigger = node(html, "button")
      panel = node(html, "[data-cw--disclosure-target=panel]")

      assert_equal "button", trigger["type"]
      assert_equal "false", trigger["aria-expanded"]
      assert_equal "faq-trigger", trigger["id"]
      assert_equal "faq-panel", trigger["aria-controls"]
      assert_equal "faq-panel", panel["id"]
      assert panel.key?("hidden"), "closed panel must be hidden"
    end

    def test_open_state_is_rendered_server_side
      html = render_default(open: true)

      assert_equal "true", node(html, "div")["data-cw--disclosure-open-value"]
      assert_equal "true", node(html, "button")["aria-expanded"]
      refute node(html, "[data-cw--disclosure-target=panel]").key?("hidden")
    end

    def test_region_labels_the_panel_and_points_it_back_at_the_trigger
      panel = node(render_default(region: true), "[data-cw--disclosure-target=panel]")

      assert_equal "region", panel["role"]
      assert_equal "faq-trigger", panel["aria-labelledby"]
    end

    def test_open_class_lands_on_the_root_controller_element
      assert_equal "is-open", node(render_default(open_class: "is-open"), "div")["data-cw--disclosure-open-class"]
    end

    def test_partial_classes_are_present_alongside_our_wiring
      assert_token "cw-disclosure", node(render_default, "div"), "class"
      assert_token "cw-disclosure__trigger", node(render_default, "button"), "class"
    end

    def test_summary_is_optional
      html = view.crosswire_disclosure(nil, id: "faq") { "only a panel".html_safe }

      assert_nil dom(html).at_css("button")
      assert_includes html, "only a panel"
    end

    def test_panel_block_is_optional
      html = view.crosswire_disclosure("Summary", id: "faq")

      assert_equal "cw--disclosure", node(html, "div")["data-controller"]
    end

    def test_for_form_yields_the_presenter_and_renders_none_of_our_markup
      yielded = nil
      view.crosswire_disclosure_for(id: "faq") { |d| yielded = d }

      assert_instance_of Crosswire::Presenters::Disclosure, yielded
      assert_equal "faq-panel", yielded.panel_id
    end
  end

  class DialogRenderTest < HelperCase
    def render_default(title = "Delete this project?", **options, &block)
      block ||= proc { "<p>body</p>".html_safe }
      view.crosswire_dialog(title, **{id: "confirm-delete", trigger_label: "Delete…"}.merge(options), &block)
    end

    def test_partial_renders_root_trigger_and_native_dialog
      html = render_default

      assert_equal "cw--dialog", node(html, "div")["data-controller"]
      assert_equal "trigger", node(html, "button")["data-cw--dialog-target"]
      assert_equal "panel", node(html, "dialog")["data-cw--dialog-target"]
    end

    def test_values_are_rendered_server_side
      root = node(render_default, "div")

      assert_equal "false", root["data-cw--dialog-open-value"]
      assert_equal "true", root["data-cw--dialog-modal-value"]
      assert_equal "true", root["data-cw--dialog-dismissable-value"]
    end

    def test_trigger_and_panel_are_wired_to_each_other
      html = render_default
      trigger = node(html, "[data-cw--dialog-target=trigger]")

      assert_equal "button", trigger["type"]
      assert_equal "dialog", trigger["aria-haspopup"]
      assert_equal "confirm-delete", trigger["aria-controls"]
      assert_equal "confirm-delete", node(html, "dialog")["id"]
    end

    def test_title_becomes_the_accessible_name
      html = render_default

      assert_equal "confirm-delete-title", node(html, "dialog")["aria-labelledby"]
      assert_equal "confirm-delete-title", node(html, "h2")["id"]
      assert_equal "Delete this project?", node(html, "h2").text.strip
    end

    def test_panel_wires_the_native_events_and_both_turbo_guards
      actions = tokens(node(render_default, "dialog"), "data-action")

      assert_includes actions, "close->cw--dialog#syncClosed"
      assert_includes actions, "cancel->cw--dialog#cancel"
      assert_includes actions, "click->cw--dialog#backdropClick"
      assert_includes actions, "turbo:before-morph-element->cw--dialog#beforeMorph"
      assert_includes actions, "turbo:before-cache->cw--dialog#reset"
    end

    def test_close_button_is_labelled
      close = node(render_default, ".cw-dialog__close")

      assert_equal "Close", close["aria-label"]
      assert_equal "button", close["type"]
      assert_equal "click->cw--dialog#close", close["data-action"]
    end

    def test_open_renders_the_native_open_attribute
      assert node(render_default(open: true), "dialog").key?("open")
      refute node(render_default, "dialog").key?("open")
    end

    def test_trigger_label_and_title_are_both_optional
      html = view.crosswire_dialog(nil, id: "bare") { "body".html_safe }

      assert_nil dom(html).at_css("button")
      assert_nil dom(html).at_css("h2")
      assert_nil node(html, "dialog")["aria-labelledby"]
    end

    def test_body_block_is_optional
      html = view.crosswire_dialog("Title", id: "bare", trigger_label: "Open")

      assert_equal "cw--dialog", node(html, "div")["data-controller"]
    end

    def test_for_form_yields_the_presenter
      yielded = nil
      view.crosswire_dialog_for(id: "d") { |d| yielded = d }

      assert_instance_of Crosswire::Presenters::Dialog, yielded
    end
  end

  class ConfirmRenderTest < HelperCase
    def render_default(**options)
      view.crosswire_confirm(**{id: "confirm", title: "Sure?", body: "No undo."}.merge(options))
    end

    def test_partial_stacks_both_controllers_on_one_dialog_element
      html = render_default

      assert_equal 1, dom(html).css("dialog").size
      assert_equal %w[cw--dialog cw--confirm], tokens(node(html, "dialog"), "data-controller")
    end

    def test_alertdialog_semantics_and_id_relationships
      html = render_default
      dialog = node(html, "dialog")

      assert_equal "alertdialog", dialog["role"]
      assert_equal "confirm-title", dialog["aria-labelledby"]
      assert_equal "confirm-body", dialog["aria-describedby"]
      assert_equal "confirm-title", node(html, "h2")["id"]
      assert_equal "confirm-body", node(html, "p")["id"]
    end

    def test_dialog_half_of_the_composition_is_present
      dialog = node(render_default, "dialog")

      assert_equal "panel", dialog["data-cw--dialog-target"]
      assert_equal "false", dialog["data-cw--dialog-dismissable-value"],
                   "a confirmation must never be dismissable by an accidental backdrop click"
      assert_equal "false", dialog["data-cw--dialog-open-value"]
    end

    def test_confirm_reacts_to_the_dialogs_own_lifecycle_events
      actions = tokens(node(render_default, "dialog"), "data-action")

      assert_includes actions, "cw--dialog:opened->cw--confirm#opened"
      assert_includes actions, "cw--dialog:closed->cw--confirm#closed"
    end

    def test_labels_and_targets_are_rendered_server_side
      html = render_default(confirm_label: "Delete", cancel_label: "Keep", destructive: true)
      dialog = node(html, "dialog")

      assert_equal "Sure?", dialog["data-cw--confirm-title-value"]
      assert_equal "No undo.", dialog["data-cw--confirm-body-value"]
      assert_equal "Delete", dialog["data-cw--confirm-confirm-label-value"]
      assert_equal "Keep", dialog["data-cw--confirm-cancel-label-value"]
      assert_equal "true", dialog["data-cw--confirm-destructive-value"]
      assert_equal "title", node(html, "h2")["data-cw--confirm-target"]
      assert_equal "body", node(html, "p")["data-cw--confirm-target"]
    end

    def test_each_button_fires_its_own_action_then_asks_the_dialog_to_close
      html = render_default

      assert_equal ["click->cw--confirm#confirm", "click->cw--dialog#close"],
                   tokens(node(html, ".cw-confirm__confirm"), "data-action")
      assert_equal ["click->cw--confirm#cancel", "click->cw--dialog#close"],
                   tokens(node(html, ".cw-confirm__cancel"), "data-action")
      assert_equal "confirmButton", node(html, ".cw-confirm__confirm")["data-cw--confirm-target"]
      assert_equal "cancelButton", node(html, ".cw-confirm__cancel")["data-cw--confirm-target"]
    end

    def test_destructive_class_lands_on_the_root_controller_element
      dialog = node(render_default(destructive: true, destructive_class: "is-destructive"), "dialog")

      assert_equal "is-destructive", dialog["data-cw--confirm-destructive-class"]
    end

    def test_for_form_yields_the_presenter
      yielded = nil
      view.crosswire_confirm_for(id: "c") { |c| yielded = c }

      assert_instance_of Crosswire::Presenters::Confirm, yielded
    end
  end

  # ---------------------------------------------------------------------------------
  # Behaviours — the seven components that own no markup
  # ---------------------------------------------------------------------------------
  class BehaviourRenderTest < HelperCase
    def test_dismiss_attrs_helper
      el = attrs(view.cw_attrs(view.crosswire_dismiss_attrs(remove: false, selector: ".banner", escape: true)))

      assert_equal "cw--dismiss", el["data-controller"]
      assert_equal "false", el["data-cw--dismiss-remove-value"]
      assert_equal ".banner", el["data-cw--dismiss-selector-value"]
      assert_equal "keydown.esc->cw--dismiss#dismiss", el["data-action"]
      assert_equal "-1", el["tabindex"], "Escape must reach the container when focus is inside it"
    end

    def test_dismiss_for_yields_a_presenter_with_a_labelled_trigger
      trigger = nil
      view.crosswire_dismiss_for(label: "Dismiss notice") { |d| trigger = attrs(view.cw_attrs(d.trigger_attrs)) }

      assert_equal "button", trigger["type"]
      assert_equal "Dismiss notice", trigger["aria-label"]
      assert_equal "click->cw--dismiss#dismiss", trigger["data-action"]
    end

    def test_transition_attrs_helper_emits_only_classes_api_attributes
      el = attrs(view.cw_attrs(view.crosswire_transition_attrs(
                                 enter: "fade", enter_from: "opacity-0", enter_to: "opacity-100",
                                 leave: "fade", leave_from: "opacity-100", leave_to: "opacity-0")))

      assert_equal "cw--transition", el["data-controller"]
      assert_equal "fade", el["data-cw--transition-enter-class"]
      assert_equal "opacity-0", el["data-cw--transition-enter-from-class"]
      assert_equal "opacity-100", el["data-cw--transition-enter-to-class"]
      assert_equal "opacity-0", el["data-cw--transition-leave-to-class"]
    end

    def test_transition_omits_classes_that_were_not_given
      el = attrs(view.cw_attrs(view.crosswire_transition_attrs(leave: "fade")))

      assert_equal "fade", el["data-cw--transition-leave-class"]
      refute el.key?("data-cw--transition-enter-class"),
             "an absent class attribute is what the controller's hasFooClass guard expects (R3)"
    end

    def test_transition_composes_with_dismiss_on_one_element
      el = attrs(view.cw_attrs(view.crosswire_dismiss_attrs,
                               view.crosswire_transition_attrs(leave: "fade"),
                               Crosswire::Presenters::Transition.new.leave_on))

      assert_equal %w[cw--dismiss cw--transition], tokens(el, "data-controller")
      assert_equal "cw--dismiss:dismissing->cw--transition#leave", el["data-action"]
    end

    def test_persist_attrs_helper
      el = attrs(view.cw_attrs(view.crosswire_persist_attrs(key: "faq", attribute: "open",
                                                            storage: "session", debounce: 250)))

      assert_equal "cw--persist", el["data-controller"]
      assert_equal "faq", el["data-cw--persist-key-value"]
      assert_equal "open", el["data-cw--persist-attribute-value"]
      assert_equal "session", el["data-cw--persist-storage-value"]
      assert_equal "250", el["data-cw--persist-debounce-value"]
    end

    def test_persist_validates_its_options_at_render_time
      assert_raises(ArgumentError) { view.crosswire_persist_attrs(key: "") }
      assert_raises(ArgumentError) { view.crosswire_persist_attrs(key: "k", storage: "cookie") }
    end

    def test_intersection_for_yields_a_presenter_carrying_the_observer_options
      el = nil
      view.crosswire_intersection_for(once: true, threshold: 0.25, root_margin: "200px") do |i|
        el = attrs(view.cw_attrs(i.root_attrs))
      end

      assert_equal "cw--intersection", el["data-controller"]
      assert_equal "true", el["data-cw--intersection-once-value"]
      assert_equal "0.25", el["data-cw--intersection-threshold-value"]
      assert_equal "200px", el["data-cw--intersection-root-margin-value"]
    end

    def test_focus_trap_for_wires_both_tab_descriptors
      el = nil
      view.crosswire_focus_trap_for(active: true, initial: "#h", active_class: "is-trapped") do |t|
        el = attrs(view.cw_attrs(t.root_attrs))
      end

      assert_equal "cw--focus-trap", el["data-controller"]
      assert_equal "true", el["data-cw--focus-trap-active-value"]
      assert_equal "#h", el["data-cw--focus-trap-initial-value"]
      assert_equal "is-trapped", el["data-cw--focus-trap-active-class"]
      assert_equal ["keydown.tab->cw--focus-trap#cycle", "keydown.shift+tab->cw--focus-trap#cycle"],
                   tokens(el, "data-action"),
                   "a bare keydown.tab filter silently drops Shift+Tab (R8a)"
    end

    def test_clipboard_for_yields_all_four_element_attribute_sets
      root = source = button = status = nil
      view.crosswire_clipboard_for(success_class: "is-copied", success_duration: 1500) do |c|
        root = attrs(view.cw_attrs(c.root_attrs))
        source = attrs(view.cw_attrs(c.source_attrs))
        button = attrs(view.cw_attrs(c.button_attrs))
        status = attrs(view.cw_attrs(c.status_attrs))
      end

      assert_equal "cw--clipboard", root["data-controller"]
      assert_equal "1500", root["data-cw--clipboard-success-duration-value"]
      assert_equal "is-copied", root["data-cw--clipboard-success-class"],
                   "Stimulus resolves data-*-class against the controller element, never a target (R3a)"
      assert_equal "source", source["data-cw--clipboard-target"]
      assert_equal "button", button["data-cw--clipboard-target"]
      assert_equal "click->cw--clipboard#copy", button["data-action"]
      assert_equal "status", status["data-cw--clipboard-target"]
      assert_equal "status", status["role"]
      assert_equal "polite", status["aria-live"]
      assert_equal "true", status["aria-atomic"]
    end

    def test_autosubmit_helper_returns_attrs_ready_for_cw_attrs
      el = attrs(view.cw_attrs(view.crosswire_autosubmit(delay: 300, event: "change", scope: "#filters"),
                               type: "search", name: "q"))

      assert_equal "cw--autosubmit", el["data-controller"]
      assert_equal "300", el["data-cw--autosubmit-delay-value"]
      assert_equal "change", el["data-cw--autosubmit-event-value"]
      assert_equal "#filters", el["data-cw--autosubmit-scope-value"]
      assert_equal "search", el["type"]
    end

    def test_autosubmit_for_yields_the_presenter
      yielded = nil
      view.crosswire_autosubmit_for(delay: 100) { |a| yielded = a }

      assert_instance_of Crosswire::Presenters::Autosubmit, yielded
    end
  end

  # ---------------------------------------------------------------------------------
  # The caller-override path, end to end through ERB. This is what
  # `Crosswire::Attributes.merge` exists for.
  # ---------------------------------------------------------------------------------
  class CallerOverrideTest < HelperCase
    def test_disclosure_partial_unions_a_caller_controller_action_and_class
      html = view.crosswire_disclosure("Shipping", id: "faq",
                                       class: "card",
                                       data: {controller: "analytics", action: "click->analytics#track"}) { "".html_safe }
      root = node(html, "div")

      assert_equal %w[cw--disclosure analytics], tokens(root, "data-controller")
      assert_equal "click->analytics#track", root["data-action"]
      assert_equal %w[card cw-disclosure], tokens(root, "class")
      # And ours survived intact:
      assert_equal "false", root["data-cw--disclosure-open-value"]
      assert_equal "faq", root["id"]
    end

    def test_dialog_partial_unions_caller_attributes
      html = view.crosswire_dialog("T", id: "d", trigger_label: "Open",
                                   class: "modal",
                                   data: {controller: "analytics", action: "keydown->analytics#key"}) { "".html_safe }
      root = node(html, "div")

      assert_equal %w[cw--dialog analytics], tokens(root, "data-controller")
      assert_equal "keydown->analytics#key", root["data-action"]
      assert_equal %w[modal cw-dialog], tokens(root, "class")
    end

    def test_confirm_partial_unions_caller_attributes_without_losing_the_stack
      html = view.crosswire_confirm(id: "c", class: "modal modal--danger",
                                    data: {controller: "analytics"})
      dialog = node(html, "dialog")

      assert_equal %w[cw--dialog cw--confirm analytics], tokens(dialog, "data-controller")
      assert_equal %w[modal modal--danger cw-confirm], tokens(dialog, "class")
      # The stacked composition is untouched:
      assert_includes tokens(dialog, "data-action"), "cw--dialog:opened->cw--confirm#opened"
    end

    def test_a_caller_action_is_unioned_with_ours_rather_than_replacing_it
      el = attrs(view.cw_attrs(Crosswire::Presenters::Dismiss.new(escape: true).root_attrs,
                               data: {action: "click->analytics#track"}))

      assert_equal ["keydown.esc->cw--dismiss#dismiss", "click->analytics#track"],
                   tokens(el, "data-action")
    end

    def test_bang_forces_replacement_and_nil_deletes
      el = attrs(view.cw_attrs(Crosswire::Presenters::Disclosure.new(id: "faq").root_attrs,
                               "data-controller!" => "only-mine", "id" => nil))

      assert_equal "only-mine", el["data-controller"]
      refute el.key?("id")
    end

    def test_merging_is_idempotent_through_a_real_render
      once = view.cw_attrs(Crosswire::Presenters::Disclosure.new(id: "faq", open: true).root_attrs).to_s
      merged = Crosswire::Attributes.merge(Crosswire::Presenters::Disclosure.new(id: "faq", open: true).root_attrs)
      twice = view.cw_attrs(merged, merged).to_s

      assert_equal once, twice
    end

    def test_behaviour_helpers_accept_caller_overrides_too
      el = attrs(view.cw_attrs(view.crosswire_persist_attrs(key: "k", class: "field",
                                                            data: {controller: "analytics"})))

      assert_equal %w[cw--persist analytics], tokens(el, "data-controller")
      assert_equal "field", el["class"]
    end
  end

  # ---------------------------------------------------------------------------------
  # The engine: initializers observed after they have actually run
  # ---------------------------------------------------------------------------------
  class EngineTest < ActiveSupport::TestCase
    def app = Rails.application

    def test_engine_is_mounted
      assert Rails.application.routes.routes.any? { |r| r.app.app == Crosswire::Engine },
             "expected Crosswire::Engine to be mounted"
    end

    def test_assets_initializer_added_the_engine_javascript_path
      paths = app.config.assets.paths.map(&:to_s)

      assert_includes paths, Crosswire::Engine.root.join("app/assets/javascripts").to_s
    end

    def test_importmap_initializer_pinned_every_controller_individually
      pins = app.importmap.packages.keys + app.importmap.directories.keys.map(&:to_s)

      assert app.importmap.directories.values.any? { |d| d.under == "crosswire/controllers" },
             "expected pin_all_from under crosswire/controllers, got #{pins.inspect}"
    end

    def test_every_controller_resolves_through_the_importmap
      json = JSON.parse(app.importmap.to_json(resolver: ActionController::Base.helpers))
      imports = json.fetch("imports")

      Crosswire.component_names.each do |name|
        key = "crosswire/controllers/#{name}_controller"
        assert imports.key?(key), "#{key} missing from the importmap: #{imports.keys.inspect}"
      end
    end

    def test_index_js_is_reachable_as_an_asset
      asset = Rails.application.assets.load_path.find("crosswire/index.js")

      refute_nil asset, "crosswire/index.js is not on the asset load path"
      assert_includes asset.content, "registerCrosswireControllers"
    end

    def test_index_js_is_added_to_the_precompile_list
      # Sprockets needs this. Under Propshaft `config.assets.precompile` survives only
      # as a compatibility shim (railtie.rb:78) and everything on `config.assets.paths`
      # is served regardless, so appending is a harmless no-op rather than the
      # NoMethodError-on-nil it looks like it should be.
      assert_includes app.config.assets.precompile, "crosswire/index.js"
    end

    def test_helpers_initializer_included_attributes_helper_into_action_view
      assert_includes ActionView::Base.ancestors, Crosswire::AttributesHelper
    end

    def test_component_helpers_are_not_included_globally
      refute_includes ActionView::Base.ancestors, Crosswire::DisclosureHelper,
                      "per-component helpers are opt-in; installing the gem must not add them"
    end

    def test_presenter_directory_is_registered_with_the_app_autoloader
      presenters = Crosswire::Engine.root.join("lib/crosswire/presenters").to_s

      assert_includes ActiveSupport::Dependencies.autoload_paths.map(&:to_s), presenters
      assert_includes Rails.autoloaders.main.dirs, presenters
    end

    # Presenters live under `lib/crosswire/presenters`, and that directory is pushed
    # onto the autoloader as a ROOT — so a naive reading says Zeitwerk would expect
    # `disclosure.rb` to define a TOP-LEVEL `Disclosure`, and would then shadow (or
    # collide with) a consumer's own `Dialog`, `Confirm` or `Persist` class. It does
    # not: `lib/crosswire.rb` requires every presenter eagerly, so Zeitwerk sees the
    # files as already loaded and registers no autoload for them at all. Pinned here
    # because it is a real hazard that happens to be neutralised by the eager requires,
    # and would come back the moment those were dropped.
    def test_presenters_do_not_leak_constants_into_the_top_level_namespace
      %i[Disclosure Dialog Confirm Dismiss Persist Transition Clipboard
         Autosubmit Intersection FocusTrap].each do |constant|
        assert_nil Object.autoload?(constant),
                   "crosswire registered a top-level autoload for #{constant}"
        refute Object.const_defined?(constant, false),
               "crosswire defined a top-level constant #{constant}"
      end
    end

    def test_shadow_check_ran_at_boot_and_passed
      assert Crosswire::ShadowCheck.new(app).run
    end

    # Both asset-facing initializers are conditional, and `test/dummy` deliberately
    # satisfies both conditions, so it cannot prove the negative branches work. A
    # jsbundling app has no `importmap`; an app with no pipeline at all has no
    # `config.assets`. Either one must still boot.
    def test_engine_boots_in_a_host_with_neither_importmap_nor_an_asset_pipeline
      script = File.expand_path("support/bare_boot.rb", __dir__)
      output = IO.popen([RbConfig.ruby, script], err: [:child, :out], &:read)

      assert $?.success?, "bare host failed to boot:\n\n#{output}"
      assert_includes output, "BARE_BOOT_OK"
      assert_includes output, "importmap=false"
      assert_includes output, "assets=false"
      assert_includes output, "attributes_helper=true",
                      "cw_attrs must be available even with no asset pipeline"
    end
  end

  # ---------------------------------------------------------------------------------
  # Whole pages through the real stack
  # ---------------------------------------------------------------------------------
  class PageRequestTest < ActionDispatch::IntegrationTest
    include Dom

    def test_every_demo_page_renders
      %w[/ /behaviours /layer0 /overrides].each do |path|
        get path

        assert_response :success, "#{path} did not render"
      end
    end

    def test_widgets_page_carries_live_wiring
      get "/"

      assert_equal "cw--disclosure", node(response.body, "#disclosure-default [data-controller]")["data-controller"]
      assert_equal %w[cw--dialog cw--confirm],
                   tokens(node(response.body, "#app-confirm"), "data-controller")
    end

    def test_behaviours_page_carries_every_behaviour_controller
      get "/behaviours"

      %w[dismiss transition persist intersection focus-trap clipboard autosubmit].each do |identifier|
        assert node(response.body, "[data-controller~='cw--#{identifier}']"),
               "cw--#{identifier} missing from /behaviours"
      end
    end

    def test_importmap_is_emitted_with_our_pins
      get "/"
      map = JSON.parse(node(response.body, "script[type=importmap]").text)

      assert map["imports"].key?("crosswire")
      assert map["imports"].key?("crosswire/controllers/disclosure_controller")
    end

    def test_the_pinned_controller_modules_actually_serve
      get "/"
      map = JSON.parse(node(response.body, "script[type=importmap]").text)

      get map["imports"].fetch("crosswire/controllers/disclosure_controller")
      assert_response :success
      assert_includes response.body, "export default class"
    end

    def test_index_module_serves_and_registers_every_controller
      get "/"
      map = JSON.parse(node(response.body, "script[type=importmap]").text)

      get map["imports"].fetch("crosswire")
      assert_response :success
      Crosswire.component_names.each do |name|
        assert_includes response.body, "crosswire/controllers/#{name}_controller"
      end
    end
  end

  # ---------------------------------------------------------------------------------
  # ShadowCheck — one real boot per scenario
  # ---------------------------------------------------------------------------------
  class ShadowCheckBootTest < ActiveSupport::TestCase
    SCRIPT = File.expand_path("support/shadow_boot.rb", __dir__)

    Result = Struct.new(:status, :message, :render, :log) do
      def raised? = status.start_with?("BOOT_RAISED")
      def error_class = status.split(" ", 2).last
    end

    def boot(scenario)
      output = IO.popen([RbConfig.ruby, SCRIPT, scenario], err: [:child, :out], &:read)
      assert $?.success?, "shadow_boot.rb #{scenario} crashed:\n#{output}"

      status, rest = output.split("---MESSAGE---", 2)
      message, rest = rest.to_s.split("---RENDER---", 2)
      render, log = rest.to_s.split("---LOG---", 2)
      Result.new(status.to_s.strip, message.to_s.strip, render.to_s, log.to_s)
    end

    def test_no_shadow_boots_cleanly_and_renders_our_own_partial
      result = boot("none")

      refute result.raised?, result.message
      assert_includes result.render, "cw-disclosure"
      refute_includes result.render, "app-shadowed"
    end

    def test_a_matching_marker_passes_and_the_apps_copy_actually_wins_at_render_time
      result = boot("match")

      refute result.raised?, result.message
      assert_includes result.render, "app-shadowed",
                      "view-path shadowing is the whole premise of D5; the app's copy must win"
      refute_includes result.log, "without a contract marker"
    end

    def test_a_stale_marker_aborts_boot_naming_the_file_and_both_versions
      result = boot("stale")

      assert result.raised?, "a stale shadow must not be allowed to boot"
      assert_equal "Crosswire::ShadowCheck::StaleShadowError", result.error_class
      assert_match %r{crosswire/_disclosure\.html\.erb}, result.message
      assert_match(/declares v0/, result.message)
      assert_match(/crosswire ships v#{Crosswire::CONTRACT_VERSION}/, result.message)
      assert_match(/crosswire:eject/, result.message, "the error must say how to fix it")
    end

    def test_a_missing_marker_warns_but_does_not_abort_boot
      result = boot("unmarked")

      refute result.raised?, result.message
      assert_match(/\[crosswire\] Overriding a crosswire partial without a contract marker/, result.log)
      assert_match %r{crosswire/_disclosure\.html\.erb}, result.log
      assert_match(/crosswire:contract v#{Crosswire::CONTRACT_VERSION}/, result.log)
      assert_includes result.render, "app-shadowed"
    end

    def test_the_check_can_be_switched_off
      result = boot("disabled")

      refute result.raised?, "config.crosswire_shadow_check = false must suppress the raise"
      assert_includes result.render, "app-shadowed"
    end
  end

  # ---------------------------------------------------------------------------------
  # Lookbook
  # ---------------------------------------------------------------------------------
  class LookbookTest < ActionDispatch::IntegrationTest
    include Dom

    def previews = Lookbook.previews

    def test_lookbook_is_mounted_and_serves
      get "/lookbook"

      assert_response :success
    end

    def test_a_preview_exists_for_every_shipped_component
      names = previews.map(&:name)

      Crosswire.component_names.each do |component|
        assert_includes names, component, "no Lookbook preview for #{component}"
      end
    end

    def test_every_scenario_of_every_preview_renders
      count = 0
      previews.each do |preview|
        preview.scenarios.each do |scenario|
          count += 1
          get "/lookbook/preview/#{preview.lookup_path}/#{scenario.name}"

          assert_response :success, "#{preview.lookup_path}/#{scenario.name} failed to render"
        end
      end

      assert_operator count, :>=, Crosswire.component_names.size
    end

    def test_every_scenario_is_inspectable
      # The inspector is what parses the @param tags, so a malformed one fails here.
      previews.each do |preview|
        preview.scenarios.each do |scenario|
          get "/lookbook/inspect/#{preview.lookup_path}/#{scenario.name}"

          assert_response :success, "#{preview.lookup_path}/#{scenario.name} is not inspectable"
        end
      end
    end

    # The gap the research flagged: Lookbook's default preview controller is a bare
    # Rails::ApplicationController, so neither engine helpers (lookbook#745) nor engine
    # view paths are present. Both are fixed by config.lookbook.preview_controller.
    def test_the_configured_preview_controller_is_ours
      assert_equal "CrosswirePreviewController", Lookbook.config.preview_controller
      assert_equal CrosswirePreviewController, Lookbook::Engine.preview_controller
    end

    def test_engine_helpers_are_callable_in_previews
      helpers = CrosswirePreviewController.helpers

      assert_respond_to helpers, :crosswire_disclosure
      assert_respond_to helpers, :cw_attrs
      Crosswire.component_names.each do |name|
        assert Crosswire.const_get(:"#{name.camelize}Helper")
                        .public_instance_methods(false)
                        .all? { |m| helpers.respond_to?(m) },
               "#{name} helper methods are not available in previews"
      end
    end

    def test_the_shipped_partials_resolve_from_the_preview_controller
      lookup = ActionView::LookupContext.new(CrosswirePreviewController.view_paths)

      %w[disclosure dialog confirm].each do |partial|
        assert lookup.find_all(partial, ["crosswire"], true).any?,
               "crosswire/_#{partial} is not on the preview controller's lookup path"
      end
    end

    def test_a_preview_renders_the_real_component_not_a_placeholder
      get "/lookbook/preview/disclosure/default"
      root = node(response.body, "[data-controller~='cw--disclosure']")

      assert_equal "faq-1", root["id"]
      assert_equal "trigger", node(response.body, "[data-cw--disclosure-target=trigger]")["data-cw--disclosure-target"]
    end

    def test_previews_are_live_and_load_the_same_importmap_the_host_app_does
      get "/lookbook/preview/disclosure/default"
      map = JSON.parse(node(response.body, "script[type=importmap]").text)

      assert map["imports"].key?("crosswire/controllers/disclosure_controller")
    end

    def test_the_caller_override_preview_shows_a_merged_controller_list
      get "/lookbook/preview/disclosure/caller_overrides"

      assert_equal %w[cw--disclosure analytics],
                   tokens(node(response.body, "#faq-3"), "data-controller")
    end

    def test_a_scenario_template_exists_for_every_scenario
      # `render_with_template` is what makes the source panel show copy-pasteable ERB
      # rather than the preview's Ruby method — which is the D6 catalog seed.
      missing = previews.flat_map do |preview|
        preview.scenarios.map do |scenario|
          path = Rails.root.join("lookbook/previews/#{preview.name}_preview/#{scenario.name}.html.erb")
          path.to_s unless path.exist?
        end
      end.compact

      assert_empty missing, "scenarios with no ERB template: #{missing.inspect}"
    end
  end
end
