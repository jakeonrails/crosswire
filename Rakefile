# frozen_string_literal: true

require "rake/testtask"
require "shellwords"

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

DUMMY = File.expand_path("test/dummy", __dir__)

desc "Start the dummy host app + Lookbook on PORT (default 3000). Lookbook: /lookbook"
task :lookbook do
  port = ENV.fetch("PORT", "3000")
  puts "  demo     http://localhost:#{port}/"
  puts "  Lookbook http://localhost:#{port}/lookbook"
  sh "cd #{DUMMY.shellescape} && bin/rails server -p #{port}"
end

desc "Rebuild site/index.html from the gem's real source, then smoke-test it in Chromium"
task :site do
  sh "ruby bin/build_site.rb"
  sh "node bin/smoke_site.mjs"
end

desc "Run only the Rails integration suite (boots test/dummy), with full output"
task :integration do
  sh "#{RbConfig.ruby.shellescape} test/crosswire/integration_test_runner.rb"
end

desc "Run only the Action Cable streams suite (boots test/dummy), with full output"
task :streams do
  sh "#{RbConfig.ruby.shellescape} test/crosswire/streams_test_runner.rb"
end

task default: %i[test]
