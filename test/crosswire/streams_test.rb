# frozen_string_literal: true

require "minitest/autorun"

module Crosswire
  # The Action Cable half of the suite lives in `streams_test_runner.rb`. This file
  # exists only to run it as a child process and fail loudly if it fails — cloned from
  # `integration_test.rb`, which explains the subprocess boundary itself (short
  # version: `test/test_helper.rb` guarantees the presenter suite never sees Rails, and
  # booting Rails anywhere in the shared in-process suite would break every sibling's
  # `refute defined?(::Rails)` assertion).
  #
  # A SEPARATE runner from `integration_test_runner.rb`, rather than folding
  # `Crosswire::Streams` coverage into that one, for two reasons: a channel failure
  # (a bad signature, a locator raising, an Action Cable version drift) gets its own
  # isolated subprocess and output instead of tangling with the much larger Rails-boot
  # suite's; and `integration_test.rb`'s own `MINIMUM_EXPECTED_RUNS` floor stays
  # meaningful — quietly inflating that count with an entire second suite's worth of
  # runs would make the floor stop saying anything real about what it's checking.
  class StreamsTest < Minitest::Test
    RUNNER = File.expand_path("streams_test_runner.rb", __dir__)

    # Guards against the child "passing" because it silently ran nothing.
    MINIMUM_EXPECTED_RUNS = 6

    def setup
      @output = IO.popen([RbConfig.ruby, RUNNER], err: [:child, :out], &:read)
      @status = $?
    end

    def test_streams_suite_passes_under_a_real_rails_boot
      assert @status.success?,
             "streams subprocess suite failed (exit #{@status.exitstatus}):\n\n#{@output}"
    end

    def test_streams_suite_actually_ran_its_tests
      summary = @output[/^(\d+) runs, (\d+) assertions, (\d+) failures, (\d+) errors/]

      refute_nil summary, "no Minitest summary in the child's output:\n\n#{@output}"

      runs, assertions, failures, errors = summary.scan(/\d+/).map(&:to_i)

      assert_operator runs, :>=, MINIMUM_EXPECTED_RUNS,
                      "only #{runs} streams tests ran; expected at least #{MINIMUM_EXPECTED_RUNS}"
      assert_operator assertions, :>, runs
      assert_equal 0, failures + errors, @output
    end
  end
end
