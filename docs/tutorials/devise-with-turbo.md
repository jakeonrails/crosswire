# Devise sign-in hangs, sign-out does nothing, and validation errors never show

You submit the sign-in form and nothing happens: no redirect, no error, no change on screen. You click "Log out" and the page sits there, still logged in. You sign up with a taken email and Devise dutifully re-renders the form with the validation error — except the browser never shows it, because Turbo already gave up on the response.

These read like three separate bugs. They're one bug in three costumes: Devise's default responses don't carry the signals Turbo needs to interpret a fetch submission, so Turbo either drops the response, can't follow it, or never fires the request that would produce it.

Fix it in the initializer:

```ruby
# config/initializers/devise.rb
Devise.setup do |config|
  # ...
  config.responder.error_status    = :unprocessable_content   # :unprocessable_entity on Rails < 8
  config.responder.redirect_status = :see_other
  config.navigational_formats      = ["*/*", :html, :turbo_stream]
end
```

And replace every Devise sign-out link with a real form:

```erb
<%= button_to "Log out", destroy_user_session_path, method: :delete %>
```

That's the whole fix. No JavaScript, no per-form Turbo overrides, no custom controllers.

Here's why each line earns its place. Turbo submits forms over fetch and decides what to do next from the response status alone. A status of 400 or higher tells Turbo the submission failed, so it renders the response body in place and your validation errors appear where the form used to be. Anything else, Turbo treats as a success and tries to navigate. `error_status = :unprocessable_content` is what makes Devise's re-rendered sign-up form actually carry that status, instead of a plain 200 that Turbo has no reason to distrust.

`redirect_status = :see_other` matters for the same reason `303` matters after any state-changing request — that's the fetch-spec rule the [redirect-after-delete tutorial](./redirect-status-after-delete.md) covers in full. Here it's enough to know that Devise's sign-in and sign-out actions are POST and DELETE, and only a 303 guarantees the browser replays the redirect as a GET instead of resubmitting the original method and body.

`navigational_formats` decides which request formats Devise treats as page navigations. A Turbo submission asks for `text/vnd.turbo-stream.html`, so without `:turbo_stream` on that list Devise classifies a failed sign-in as non-navigational and answers with a bare 401 instead of its normal HTML failure response. Turbo gets a status it knows is a failure and an empty body to render. That's the hang.

The sign-out fix is a different mechanism, not a status code. `link_to "Log out", ..., method: :delete` depends on turning a plain anchor tag into a DELETE request client-side, and Turbo doesn't do that the way `rails-ujs` used to. A `button_to` renders an actual `<form method="post">` with a `_method=delete` field, which is exactly the kind of element Turbo intercepts and submits. The link was never going to fire a request Turbo could see.

If you've been fighting this bug for a while, you've probably already found the old answer, and it's worth saying plainly: it's wrong now. Setting `data-turbo: false` on Devise's forms, pulling in the forked `error-code-422` branch, or dropping a custom `TurboFailureApp`/`TurboController` from the Devise wiki into your app — all of that was necessary before Devise 4.9 shipped native Turbo support in 2023, and all of it is dead weight today. The forked branch and the custom failure app in particular are still the accepted answer on the 14.8k-view Hotwired forum thread on this exact problem, which is why they keep getting copied into apps that don't need them. If you have any of these in your codebase, pull them out before adding the config above — they'll fight each other.

Before you reach for Devise at all: Rails 8's `bin/rails generate authentication` generates a from-scratch, cookie-session auth system that's Turbo-correct on day one, no responder configuration required. It's not a Devise replacement in every sense — you lose Devise's confirmable/lockable/recoverable modules and the ecosystem of extensions built on top of it — but if you're starting a new app and don't need those, it's worth generating before you `bundle add devise` out of habit.

This config covers Devise's own controllers. If you've overridden `respond_with` or written custom `create`/`destroy` actions in a `SessionsController` or `RegistrationsController` that subclasses Devise's, you're responsible for returning these same statuses yourself — the initializer settings only apply to the responder Devise's own controllers use.
