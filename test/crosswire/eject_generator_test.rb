# frozen_string_literal: true

require "minitest/autorun"

module Crosswire
  # The real `crosswire:eject` generator specs, using Rails::Generators::TestCase,
  # live in eject_generator_test_runner.rb — that is "the one file in the suite
  # allowed to load Rails" (generators are inherently a Rails concern). But "allowed
  # to load Rails" cannot mean "poisons every sibling presenter test's
  # `refute defined?(::Rails)` assertion," and that is exactly what would happen if
  # it were `require`d in-process, because the documented way to run the whole suite
  # loads every `*_test.rb` file into ONE process:
  #
  #   ruby -Ilib -Itest -e 'Dir["test/**/*_test.rb"].each { |f| require File.expand_path(f) }'
  #
  # `test/test_helper.rb` deliberately never boots Rails so that presenters stay
  # unit-testable without it (D5); a Rails boot anywhere in that shared process would
  # make `defined?(::Rails)` true for every other file's assertion of that too.
  #
  # A subprocess is the only boundary that gives the generator test a real Rails
  # environment without contaminating everyone else's. So this file — the one that
  # actually matches `*_test.rb` and gets loaded in-process — does no more than shell
  # out to the runner and fail loudly if it fails. Rails is only ever loaded inside
  # that child's own address space.
  class EjectGeneratorTest < Minitest::Test
    RUNNER = File.expand_path("eject_generator_test_runner.rb", __dir__)

    def test_eject_generator_suite_passes_under_a_real_rails_boot
      output = IO.popen([RbConfig.ruby, RUNNER], err: [:child, :out], &:read)
      status = $?

      assert status.success?,
             "eject generator subprocess suite failed (exit #{status.exitstatus}):\n\n#{output}"
    end
  end
end
