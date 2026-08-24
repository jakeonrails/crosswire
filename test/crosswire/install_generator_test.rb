# frozen_string_literal: true

require "minitest/autorun"

module Crosswire
  # The real `crosswire:install` generator specs, using Rails::Generators::TestCase,
  # live in install_generator_test_runner.rb and run in a child process — for exactly
  # the reason eject_generator_test.rb documents in full: the documented way to run
  # the suite loads every `*_test.rb` into ONE process, `test/test_helper.rb`
  # deliberately never boots Rails (D5), and a Rails boot anywhere in that shared
  # process would poison every presenter test's `refute defined?(::Rails)`. A
  # subprocess is the only boundary that gives a generator test a real Rails
  # environment without contaminating everyone else's.
  class InstallGeneratorTest < Minitest::Test
    RUNNER = File.expand_path("install_generator_test_runner.rb", __dir__)

    def test_install_generator_suite_passes_under_a_real_rails_boot
      output = IO.popen([RbConfig.ruby, RUNNER], err: [:child, :out], &:read)
      status = $?

      assert status.success?,
             "install generator subprocess suite failed (exit #{status.exitstatus}):\n\n#{output}"
    end
  end
end
