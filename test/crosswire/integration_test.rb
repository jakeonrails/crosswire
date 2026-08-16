# frozen_string_literal: true

require "minitest/autorun"

module Crosswire
  # The Rails-booting half of the suite lives in `integration_test_runner.rb`. This file
  # exists only to run it as a child process and fail loudly if it fails.
  #
  # Why a subprocess, and not just `require`: the documented way to run the whole suite
  # loads every `*_test.rb` file into ONE process —
  #
  #   ruby -Ilib -Itest -e 'Dir["test/**/*_test.rb"].each { |f| require File.expand_path(f) }'
  #
  # — and `test/test_helper.rb` deliberately never boots Rails, so that presenters stay
  # usable (and unit-testable) without it. That guarantee is asserted explicitly by
  # `refute defined?(::Rails)` in the presenter tests. Booting Rails anywhere in that
  # shared process would make `defined?(::Rails)` true for every one of them, and the
  # guarantee would quietly stop meaning anything.
  #
  # A subprocess is the only boundary that gives the integration suite a real Rails
  # environment — a booted `test/dummy` app, real ERB rendering, real routes, a real
  # asset pipeline — without contaminating everyone else's. Rails is loaded only inside
  # that child's own address space. This is the same arrangement `eject_generator_test.rb`
  # uses, for the same reason.
  class IntegrationTest < Minitest::Test
    RUNNER = File.expand_path("integration_test_runner.rb", __dir__)

    # Guards against the child "passing" because it silently ran nothing.
    MINIMUM_EXPECTED_RUNS = 80

    def setup
      @output = IO.popen([RbConfig.ruby, RUNNER], err: [:child, :out], &:read)
      @status = $?
    end

    def test_integration_suite_passes_under_a_real_rails_boot
      assert @status.success?,
             "integration subprocess suite failed (exit #{@status.exitstatus}):\n\n#{@output}"
    end

    def test_integration_suite_actually_ran_its_tests
      summary = @output[/^(\d+) runs, (\d+) assertions, (\d+) failures, (\d+) errors/]

      refute_nil summary, "no Minitest summary in the child's output:\n\n#{@output}"

      runs, assertions, failures, errors = summary.scan(/\d+/).map(&:to_i)

      assert_operator runs, :>=, MINIMUM_EXPECTED_RUNS,
                      "only #{runs} integration tests ran; expected at least #{MINIMUM_EXPECTED_RUNS}"
      assert_operator assertions, :>, runs
      assert_equal 0, failures + errors, @output
    end
  end
end
