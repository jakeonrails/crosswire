# frozen_string_literal: true

# The actual `crosswire:eject` generator specs, using Rails::Generators::TestCase —
# generators are inherently a Rails concern, so this is the one file in the suite
# allowed to boot Rails. It deliberately does NOT `require "test_helper"`, whose whole
# point is that it never loads Rails (see docs/DECISIONS.md D5, and
# `test/crosswire/presenters/disclosure_test.rb`'s assertion of that).
#
# This file is NOT named `*_test.rb` on purpose and is never `require`d directly.
# `eject_generator_test.rb` runs it as its own child process (see the comment there
# for why) — so when you run this file directly, e.g.
#
#   ruby test/crosswire/eject_generator_test_runner.rb
#
# it works as a normal, self-contained Minitest suite.

require "rails/all"
require "rails/generators/test_case"

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "crosswire"
require "generators/crosswire/eject/eject_generator"

require "minitest/autorun"

module Crosswire
  class EjectGeneratorTest < Rails::Generators::TestCase
    tests Crosswire::Generators::EjectGenerator
    destination File.expand_path("../../tmp/eject_generator", __dir__)
    setup :prepare_destination

    def partial_path(name) = "app/views/crosswire/_#{name}.html.erb"
    def controller_path(name) = "app/javascript/controllers/#{name}_controller.js"

    def source_partial(name) = Crosswire::Engine.root.join("app/views/crosswire/_#{name}.html.erb")

    # --- markup tier (default) --------------------------------------------------

    def test_markup_ejection_writes_the_partial_with_the_correct_contract_marker
      run_generator ["disclosure"]

      assert_file partial_path("disclosure") do |content|
        assert_equal "<%# crosswire:contract v#{Crosswire::CONTRACT_VERSION} %>",
                     content.lines.first.strip
      end
    end

    def test_markup_ejection_copies_the_real_gem_partial_byte_for_byte
      run_generator ["disclosure"]

      assert_file partial_path("disclosure") do |content|
        assert_equal File.read(source_partial("disclosure")), content
      end
    end

    def test_markup_ejection_does_not_touch_the_controller
      run_generator ["disclosure"]

      assert_no_file controller_path("disclosure")
    end

    # --- --controller tier -------------------------------------------------------

    def test_controller_ejection_writes_both_partial_and_controller
      run_generator ["disclosure", "--controller"]

      assert_file partial_path("disclosure")
      assert_file controller_path("disclosure")
    end

    def test_controller_ejection_message_warns_about_the_identifier_and_upgrades
      output = run_generator ["disclosure", "--controller"]

      assert_match(/cw--disclosure/, output)
      assert_match(/own.*identifier/i, output)
      assert_match(/will not receive any more fixes/i, output)
    end

    def test_controller_ejection_on_a_partial_less_component_writes_only_the_controller
      run_generator ["dismiss", "--controller"]

      assert_file controller_path("dismiss")
      assert_no_file partial_path("dismiss")
    end

    # --- --all -----------------------------------------------------------------------

    def test_all_ejects_every_component_that_has_a_partial
      run_generator ["--all"]

      %w[confirm dialog disclosure].each { |name| assert_file partial_path(name) }
    end

    def test_all_does_not_eject_partial_less_components
      run_generator ["--all"]

      assert_no_file partial_path("dismiss")
    end

    # --- partial-less component, markup tier (default) ---------------------------

    def test_partial_less_component_writes_nothing_and_explains_itself
      output = run_generator ["dismiss"]

      assert_no_file partial_path("dismiss")
      assert_no_file controller_path("dismiss")
      assert_match(/no markup/i, output)
      assert_match(/behaviour/i, output)
      assert_match(/--controller/, output)
    end

    # --- unknown component name --------------------------------------------------

    def test_unknown_component_fails_helpfully_and_exits_non_zero
      error = assert_raises(SystemExit) { run_generator ["not-a-real-component"] }

      assert_equal 1, error.status
    end

    def test_unknown_component_output_lists_known_components
      output = capture(:stderr) do
        assert_raises(SystemExit) { run_generator ["not-a-real-component"] }
      end

      assert_match(/not-a-real-component/, output)
      assert_match(/disclosure/, output)
    end

    def test_no_component_and_no_all_fails_helpfully
      assert_raises(SystemExit) { run_generator [] }
    end

    # --- idempotency / --force ----------------------------------------------------

    def test_rerunning_without_force_does_not_clobber_a_customized_file
      run_generator ["disclosure"]
      customized = "<%# crosswire:contract v#{Crosswire::CONTRACT_VERSION} %>\n<!-- mine -->\n"
      File.write(File.join(destination_root, partial_path("disclosure")), customized)

      with_stubbed_collision_answer("n") { run_generator ["disclosure"] }

      assert_file partial_path("disclosure") do |content|
        assert_equal customized, content
      end
    end

    def test_force_overwrites_an_existing_copy
      run_generator ["disclosure"]
      File.write(File.join(destination_root, partial_path("disclosure")), "<!-- mine -->\n")

      run_generator ["disclosure", "--force"]

      assert_file partial_path("disclosure") do |content|
        assert_equal File.read(source_partial("disclosure")), content
      end
    end

    def test_rerunning_with_identical_content_is_a_silent_no_op
      run_generator ["disclosure"]
      original_mtime = File.mtime(File.join(destination_root, partial_path("disclosure")))

      run_generator ["disclosure"]

      assert_equal original_mtime, File.mtime(File.join(destination_root, partial_path("disclosure")))
    end

    private

    # Simulates answering Thor's file-collision prompt without touching real stdin.
    # Thor prefers the `readline` gem when it's loaded, which talks to the
    # controlling terminal directly rather than $stdin, so stubbing $stdin would not
    # be reliable (and could hang a non-interactive test run waiting on a real
    # terminal). Stubbing Thor::LineEditor.readline itself is deterministic. Done by
    # hand (rather than minitest/mock's Object#stub) so this doesn't depend on which
    # minitest happens to resolve when the suite is run without Bundler.
    def with_stubbed_collision_answer(answer)
      original = Thor::LineEditor.method(:readline)
      Thor::LineEditor.define_singleton_method(:readline) { |*_args| answer }
      yield
    ensure
      Thor::LineEditor.define_singleton_method(:readline, original)
    end
  end
end
