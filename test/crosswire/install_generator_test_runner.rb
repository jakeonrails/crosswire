# frozen_string_literal: true

# The actual `crosswire:install` generator specs, using Rails::Generators::TestCase —
# generators are inherently a Rails concern, so this file (like
# eject_generator_test_runner.rb and skills_generator_test_runner.rb, whose pattern it
# follows) boots Rails and is therefore NOT named `*_test.rb` and never `require`d
# in-process. `install_generator_test.rb` runs it as a child process; run directly,
# e.g.
#
#   ruby test/crosswire/install_generator_test_runner.rb
#
# it works as a normal, self-contained Minitest suite.

require "rails/all"
require "rails/generators/test_case"

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "crosswire"
require "generators/crosswire/install/install_generator"

require "minitest/autorun"

module Crosswire
  class InstallGeneratorTest < Rails::Generators::TestCase
    tests Crosswire::Generators::InstallGenerator
    destination File.expand_path("../../tmp/install_generator", __dir__)
    setup :prepare_destination

    MANIFEST = "app/assets/stylesheets/crosswire.css"
    LOCAL_TOKENS = "app/assets/stylesheets/crosswire/ui/tokens.css"

    # --- default (no flags) -------------------------------------------------------

    def test_writes_the_manifest_importing_the_gem_bundle
      run_generator

      assert_file MANIFEST do |content|
        assert_match(/@import "crosswire\/ui\.css";/, content)
      end
    end

    def test_does_not_write_a_local_tokens_copy_by_default
      run_generator

      assert_no_file LOCAL_TOKENS
    end

    def test_prints_the_stylesheet_link_tag_to_add
      output = run_generator

      assert_match(/stylesheet_link_tag "crosswire"/, output)
    end

    def test_does_not_mention_tailwind_by_default
      run_generator

      assert_file MANIFEST do |content|
        refute_match(/tailwind/i, content)
      end
    end

    # --- --tokens --------------------------------------------------------------------

    def test_tokens_flag_copies_the_real_gem_tokens_css_byte_for_byte
      run_generator ["--tokens"]

      source = Crosswire::Engine.root.join("app/assets/stylesheets/crosswire/ui/tokens.css")
      assert_file LOCAL_TOKENS do |content|
        assert_equal File.read(source), content
      end
    end

    def test_tokens_flag_imports_the_local_copy_after_the_bundle
      run_generator ["--tokens"]

      assert_file MANIFEST do |content|
        bundle_index = content.index('@import "crosswire/ui.css"')
        tokens_index = content.index('@import "crosswire/ui/tokens.css"')

        refute_nil bundle_index
        refute_nil tokens_index
        assert_operator bundle_index, :<, tokens_index
      end
    end

    # --- --tailwind --------------------------------------------------------------------

    def test_tailwind_flag_appends_a_placeholder_comment_and_writes_no_mapping_file
      run_generator ["--tailwind"]

      assert_file MANIFEST do |content|
        assert_match(/v1\.1/, content)
      end
      assert_no_file "app/assets/stylesheets/crosswire/ui/tailwind.css"
    end

    # --- idempotency / --force ----------------------------------------------------

    def test_rerunning_without_force_does_not_clobber_a_customized_manifest
      run_generator
      customized = "/* mine */\n"
      File.write(File.join(destination_root, MANIFEST), customized)

      with_stubbed_collision_answer("n") { run_generator }

      assert_file MANIFEST do |content|
        assert_equal customized, content
      end
    end

    def test_force_overwrites_an_existing_manifest
      run_generator
      File.write(File.join(destination_root, MANIFEST), "/* mine */\n")

      run_generator ["--force"]

      assert_file MANIFEST do |content|
        assert_match(/@import "crosswire\/ui\.css";/, content)
      end
    end

    def test_rerunning_with_identical_content_is_a_silent_no_op
      run_generator
      original_mtime = File.mtime(File.join(destination_root, MANIFEST))

      run_generator

      assert_equal original_mtime, File.mtime(File.join(destination_root, MANIFEST))
    end

    private

    # Same technique, for the same readline-gem reason, as
    # eject_generator_test_runner.rb / skills_generator_test_runner.rb.
    def with_stubbed_collision_answer(answer)
      original = Thor::LineEditor.method(:readline)
      Thor::LineEditor.define_singleton_method(:readline) { |*_args| answer }
      yield
    ensure
      Thor::LineEditor.define_singleton_method(:readline, original)
    end
  end
end
