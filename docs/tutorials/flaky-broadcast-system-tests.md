# The broadcast is in your logs. Capybara never saw it.

Your system test clicks something, a broadcast goes out, and the assertion times out waiting for content that — according to the server log two lines above the failure — was broadcast successfully. It passes four times out of five. On the fifth, nothing about the test changed: same click, same broadcast, same assertion. No JavaScript error, no slow response, just a `<turbo-stream>` message that never reached the page.

This isn't a timing problem you fix by waiting longer. It's a subscription that isn't listening yet.

Fix it in the test environment:

```ruby
# config/environments/test.rb
config.turbo.test_connect_after_actions << :click_link
config.turbo.test_connect_after_actions << :click_button
```

That's the whole fix. Two lines, no gem, no retry logic.

Here's the race those two lines close. `turbo_stream_from` renders a `<turbo-cable-stream-source signed-stream-name="...">` element, and that element connects to Action Cable **asynchronously** — the WebSocket handshake is a real round trip, not something that finishes in the same tick as the page render. So the sequence in a flaky test looks like this: your test clicks a link, the browser navigates and starts opening the cable connection, your test immediately does whatever causes the server-side broadcast — creates a record, calls a job — the broadcast goes out over Action Cable, and because the subscription hasn't confirmed yet, nobody's listening. Action Cable doesn't queue the message for a subscriber that shows up a moment later; it's just gone. Your assertion then waits on a DOM element that was never going to appear, and all `default_max_wait_time` buys you is a slower failure. It flakes instead of failing outright because the outcome is a coin toss: sometimes the handshake wins the race, sometimes the broadcast does.

turbo-rails already ships the fix; it just isn't wired to the action your test uses. `Turbo::SystemTestHelper` — `lib/turbo/system_test_helper.rb` — defines:

```ruby
# Delay until every `<turbo-cable-stream-source>` element present in the page
# is ready to receive broadcasts
def connect_turbo_cable_stream_sources(**options, &block)
  all(:turbo_cable_stream_source, **options, connected: false, wait: 0).each do |element|
    element.assert_matches_selector(:turbo_cable_stream_source, **options, connected: true, &block)
  end
end
```

The helper is included in every system test — the catch is which Capybara actions turbo-rails wraps with a call to it. From `lib/turbo/engine.rb`:

```ruby
config.turbo.test_connect_after_actions = %i[visit]
```

Only `visit`. If your test navigates the way a real Turbo app navigates — by clicking a link, which is a Turbo Drive visit under the hood, not a fresh Capybara `visit` call — the automatic wait never runs. The fix isn't missing from turbo-rails; it's scoped to the one action type that ordinary usage skips.

If you'd rather not touch global test config, call the helper directly at the point that needs it:

```ruby
test "a new message appears without a reload" do
  visit room_path(rooms(:general))
  click_link "Enter room"
  connect_turbo_cable_stream_sources

  Message.create!(room: rooms(:general), content: "Deploy is done", user: users(:alice))

  assert_selector "#messages .message", text: "Deploy is done"
end
```

That's the surgical version: one call, right before the action that triggers the broadcast, no change to how every other test in the suite behaves. The helper also registers `assert_turbo_cable_stream_source` and `assert_no_turbo_cable_stream_source`, worth reaching for when you want to assert the subscription state directly instead of inferring it from whether content showed up.

Don't reach for `sleep` here — Capybara already polls up to `default_max_wait_time`, and a `sleep` just makes the failure rarer, not gone. Don't guard the assertion with `!page.has_css?` either; it burns the full wait and can still pass before the element you're waiting for shows up.

This exact problem has an 11,000-view thread on discuss.hotwired.dev ("Capybara wait_for_ajax replacement for turbo_stream responses", thread 2269) and a cluster of Stack Overflow questions behind it. The advice that survives is the generic kind: never assert immediately after a click, never `sleep`, assert on DOM state, wait for `.turbo-progress-bar` or `turbo-frame[busy]` to disappear. None of it is wrong. None of it mentions `test_connect_after_actions`. The fix has been sitting in turbo-rails' engine config the whole time.

One honest limit: your test environment's Action Cable adapter is `:test`, even if production runs `solid_cable` or Redis. Fixing this race gets your broadcast showing up reliably in the browser — it doesn't mean your test suite has ever exercised the adapter your app actually deploys.
