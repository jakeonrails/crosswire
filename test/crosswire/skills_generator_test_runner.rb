# frozen_string_literal: true

# The actual `crosswire:skills` generator specs, using Rails::Generators::TestCase —
# generators are inherently a Rails concern, so this file (like
# eject_generator_test_runner.rb, whose pattern it follows) boots Rails and is
# therefore NOT named `*_test.rb` and never `require`d in-process.
# `skills_generator_test.rb` runs it as a child process; run directly, e.g.
#
#   ruby test/crosswire/skills_generator_test_runner.rb
#
# it works as a normal, self-contained Minitest suite.

require "rails/all"
require "rails/generators/test_case"

$LOAD_PATH.unshift File.expand_path("../../lib", __dir__)
require "crosswire"
require "generators/crosswire/skills/skills_generator"

require "minitest/autorun"

module Crosswire
  class SkillsGeneratorTest < Rails::Generators::TestCase
    tests Crosswire::Generators::SkillsGenerator
    destination File.expand_path("../../tmp/skills_generator", __dir__)
    setup :prepare_destination

    SKILLS_DIR = Crosswire::Engine.root.join("skills")

    # Discovered from the gem, never hardcoded — the same rule the generator itself
    # follows, so this suite stays correct as skills are added.
    def shipped_skills
      SKILLS_DIR.children.select(&:directory?).map { |d| d.basename.to_s }.sort
    end

    def skill_path(name, file = "SKILL.md") = ".claude/skills/#{name}/#{file}"

    # --- copying -----------------------------------------------------------------

    def test_copies_every_shipped_skill
      run_generator

      refute_empty shipped_skills
      shipped_skills.each { |name| assert_file skill_path(name) }
    end

    def test_copies_skill_files_byte_for_byte
      run_generator

      shipped_skills.each do |name|
        assert_file skill_path(name) do |content|
          assert_equal File.read(SKILLS_DIR.join(name, "SKILL.md")), content
        end
      end
    end

    def test_copies_sibling_reference_files_not_just_skill_md
      run_generator

      siblings = shipped_skills.flat_map do |name|
        Dir[SKILLS_DIR.join(name, "*").to_s]
          .select { |f| File.file?(f) && File.basename(f) != "SKILL.md" }
          .map { |f| [name, File.basename(f)] }
      end

      refute_empty siblings, "expected at least one skill to ship a sibling reference file"
      siblings.each { |name, file| assert_file skill_path(name, file) }
    end

    def test_summary_names_what_it_copied
      output = run_generator

      assert_match(/\.claude\/skills/, output)
      shipped_skills.each { |name| assert_match(/#{Regexp.escape(name)}/, output) }
    end

    # --- idempotency / --force ---------------------------------------------------

    def test_rerunning_with_identical_content_is_a_silent_no_op
      run_generator
      target = File.join(destination_root, skill_path(shipped_skills.first))
      original_mtime = File.mtime(target)

      run_generator

      assert_equal original_mtime, File.mtime(target)
    end

    def test_rerunning_without_force_does_not_clobber_a_customized_file
      run_generator
      target = File.join(destination_root, skill_path(shipped_skills.first))
      customized = "customized by the host app\n"
      File.write(target, customized)

      with_stubbed_collision_answer("n") { run_generator }

      assert_equal customized, File.read(target)
    end

    def test_force_overwrites_an_existing_copy
      run_generator
      name = shipped_skills.first
      File.write(File.join(destination_root, skill_path(name)), "customized\n")

      run_generator ["--force"]

      assert_file skill_path(name) do |content|
        assert_equal File.read(SKILLS_DIR.join(name, "SKILL.md")), content
      end
    end

    private

    # Simulates answering Thor's file-collision prompt without touching real stdin —
    # same technique, for the same readline-gem reason, as
    # eject_generator_test_runner.rb.
    def with_stubbed_collision_answer(answer)
      original = Thor::LineEditor.method(:readline)
      Thor::LineEditor.define_singleton_method(:readline) { |*_args| answer }
      yield
    ensure
      Thor::LineEditor.define_singleton_method(:readline, original)
    end
  end
end
