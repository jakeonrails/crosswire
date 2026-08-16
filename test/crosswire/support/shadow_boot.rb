# frozen_string_literal: true

# Boots `test/dummy` with an app-level partial shadowing one of crosswire's, and reports
# what `Crosswire::ShadowCheck` did about it.
#
# ShadowCheck runs from the engine's `config.after_initialize`, resolves partials through
# the app's own `LookupContext`, and either raises or writes to `Rails.logger`. None of
# that can be exercised in-process from a suite that has already booted — the app's view
# paths are fixed at boot and the logger is created during it. So each scenario gets its
# own real boot in its own process. This script is that process.
#
#   ruby test/crosswire/support/shadow_boot.rb <scenario>
#
#     none      no shadow at all — ours wins, check passes silently
#     match     shadow declaring the current contract version — passes
#     stale     shadow declaring v0 — must raise StaleShadowError
#     unmarked  shadow with no marker at all — must warn, must NOT raise
#     disabled  a stale shadow with config.crosswire_shadow_check = false — must not raise
#
# Output protocol, read by `integration_test_runner.rb`:
#
#   BOOT_OK | BOOT_RAISED <ErrorClass>
#   ---MESSAGE---   (the exception message, if any)
#   ---RENDER---    (body of GET / , or the string RENDER_SKIPPED)
#   ---LOG---       (everything written to Rails.logger during boot)

require "fileutils"
require "tmpdir"

scenario = ARGV.fetch(0)
root = File.expand_path("../../..", __dir__)

$LOAD_PATH.unshift File.join(root, "lib")
require "crosswire/version"

shadow_dir = Dir.mktmpdir("crosswire-shadow")
log_file = File.join(shadow_dir, "boot.log")

marker =
  case scenario
  when "match"             then "<%# crosswire:contract v#{Crosswire::CONTRACT_VERSION} %>\n"
  when "stale", "disabled" then "<%# crosswire:contract v0 %>\n"
  when "unmarked"          then ""
  end

unless scenario == "none"
  FileUtils.mkdir_p(File.join(shadow_dir, "crosswire"))
  File.write(
    File.join(shadow_dir, "crosswire", "_disclosure.html.erb"),
    <<~ERB
      #{marker}<section <%= cw_attrs(disclosure.root_attrs, class: "app-shadowed") %>>
        <button <%= cw_attrs(disclosure.trigger_attrs) %>><%= summary %></button>
        <div <%= cw_attrs(disclosure.panel_attrs) %>><%= panel %></div>
      </section>
    ERB
  )
  ENV["CROSSWIRE_EXTRA_VIEW_PATH"] = shadow_dir
end

ENV["CROSSWIRE_SHADOW_CHECK"] = "false" if scenario == "disabled"
ENV["CROSSWIRE_LOG_TO"] = log_file
ENV["RAILS_ENV"] ||= "test"

status = "BOOT_OK"
message = ""
rendered = "RENDER_SKIPPED"

begin
  require File.join(root, "test/dummy/config/environment")

  require "action_dispatch/testing/integration"
  session = ActionDispatch::Integration::Session.new(Rails.application)
  session.host! "example.org"
  session.get "/"
  rendered = session.response.body
rescue Exception => e # rubocop:disable Lint/RescueException -- reporting, not handling
  status = "BOOT_RAISED #{e.class}"
  message = e.message
end

Rails.logger.flush if defined?(Rails) && Rails.respond_to?(:logger) && Rails.logger.respond_to?(:flush)

puts status
puts "---MESSAGE---"
puts message
puts "---RENDER---"
puts rendered
puts "---LOG---"
puts(File.exist?(log_file) ? File.read(log_file) : "")
