# frozen_string_literal: true

require "rake/testtask"

# Minitest auto-discovers plugins from every loaded gem. Because the Gemfile pins `rails`
# for the generator suite, that discovery finds railties' `minitest/rails_plugin.rb`, which
# **defines `Rails` before any test body runs** — breaking the `refute defined?(::Rails)`
# assertion that guarantees presenters stay usable without Rails (D5).
#
# The leak is environmental, not ours: it reproduces with zero crosswire files loaded.
# `MT_NO_PLUGINS` disables that discovery, so `rake test` behaves identically to the plain
# `ruby -Ilib -Itest ...` invocation. Without it, `bundle exec rake test` fails and the
# generator suite gets blamed for something railties did.
ENV["MT_NO_PLUGINS"] = "1"

Rake::TestTask.new(:test) do |t|
  t.libs << "test" << "lib"
  t.pattern = "test/**/*_test.rb"
  t.warning = false
end

desc "Run the JS controller tests"
task :js do
  sh "npm test"
end

task default: %i[test]
