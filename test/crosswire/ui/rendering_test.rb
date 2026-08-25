# frozen_string_literal: true

require "minitest/autorun"

module Crosswire
  module UI
    # The Rails-booting half of the suite lives in `rendering_test_runner.rb`. This
    # file exists only to run it as a child process and fail loudly if it fails —
    # cloned from `test/crosswire/integration_test.rb`, which explains the subprocess
    # boundary itself (short version: `test/test_helper.rb` guarantees the presenter
    # suite never sees Rails, and booting Rails anywhere in the shared in-process
    # suite would break every sibling's `refute defined?(::Rails)` assertion).
    #
    # A SEPARATE runner from `integration_test_runner.rb`, for the same reason
    # `streams_test_runner.rb` is separate from it: a UI-tier rendering failure gets
    # its own isolated subprocess and output instead of tangling with the much
    # larger primitive-tier suite's, and `integration_test.rb`'s own
    # `MINIMUM_EXPECTED_RUNS` floor stays meaningful.
    class RenderingTest < Minitest::Test
      RUNNER = File.expand_path("rendering_test_runner.rb", __dir__)

      # Guards against the child "passing" because it silently ran nothing.
      MINIMUM_EXPECTED_RUNS = 6

      def setup
        @output = IO.popen([RbConfig.ruby, RUNNER], err: [:child, :out], &:read)
        @status = $?
      end

      def test_rendering_suite_passes_under_a_real_rails_boot
        assert @status.success?,
               "UI rendering subprocess suite failed (exit #{@status.exitstatus}):\n\n#{@output}"
      end

      def test_rendering_suite_actually_ran_its_tests
        summary = @output[/^(\d+) runs, (\d+) assertions, (\d+) failures, (\d+) errors/]

        refute_nil summary, "no Minitest summary in the child's output:\n\n#{@output}"

        runs, assertions, failures, errors = summary.scan(/\d+/).map(&:to_i)

        assert_operator runs, :>=, MINIMUM_EXPECTED_RUNS,
                        "only #{runs} UI rendering tests ran; expected at least #{MINIMUM_EXPECTED_RUNS}"
        assert_operator assertions, :>, runs
        assert_equal 0, failures + errors, @output
      end
    end
  end
end
