# 30 Days of Hotwire — Andrea (@itsameandrea, formerly @ilrock__)

> Primary-source extraction of the "30 Days of Hotwire tips" Twitter series,
> February 19 – March 21, 2023.

**Container thread:** https://x.com/itsameandrea/status/1631315562390519809
**Companion repo (all 30 days as commits):** https://github.com/itsameandrea/thirty_days_of_hotwire
(the repo was originally at `github.com/ilrock/thirty_days_of_hotwire`; both redirect)

## How this file was built

Each day of the series is a separate Twitter thread linked from the container tweet.
The narrative prose below is taken from those threads (OP posts only). **The code is
transcribed from the corresponding commit in the companion repo**, not from the tweet
screenshots — the screenshots show the same code, but the repo is byte-exact and
includes files the screenshots cropped out. Where a tip's technique differs between
its first commit and a follow-up refactor Andrea made (Days 1 and 2), the final state
is presented and the difference is noted.

The app is a Rails 7 "kitchen sink" — Tailwind + TailwindUI markup, Devise for auth,
importmap-style Stimulus controllers under `app/javascript/controllers/`. Long stretches
of purely decorative Tailwind markup have occasionally been elided with a comment; every
line of Ruby, ERB logic, Stimulus JS and Turbo Stream template is verbatim.

## Recurring building blocks

A handful of things are built once and reused all series. Worth reading first:

- **`autosubmit_controller.js`** (Day 1) — debounced `requestSubmit()`. Used by Days 1, 7,
  12, 14, 18, 20.
- **`stream_animations_controller.js`** (Day 3) — declarative enter/leave animations on
  Turbo Stream appends and removes. Reused Day 14.
- **The self-replacing lazy frame** (Day 5) — a `turbo_frame_tag` with
  `loading: :lazy` whose response replaces the frame with a new one pointing one page
  further on.
- **`turbo_frame_tag "flash"` in the layout** (Day 11) — a named target any
  `.turbo_stream.erb` can update, plus `flash.now` in the controller.
- **`data-turbo-permanent`** (Days 17, 20, 25) — keeps an element's state alive across a
  frame reload.

---

## Day 1 — (Nearly) JS-less multiple select input

**Source:** https://x.com/itsameandrea/status/1627308771361050624  ·  **Date:** 2023-02-19  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/a9583eb7a3867ffbafde68800c67c7d935afe743 (plus refactor `47de131`)

A StackOverflow-style tag picker: type into a combobox, see matching technologies in a dropdown, click one to add it as a badge, click a badge's ✕ to remove it, and if nothing matches, click "Add <query>" to create the record and favourite it in one request. The only JavaScript in the whole feature is a three-line debounced-autosubmit Stimulus controller. Everything else is a `GET` form scoped to a Turbo Frame plus ordinary `button_to` calls that re-render the enclosing frame — no client-side state, no component library.

### How it works

1. One tiny Stimulus controller debounces the form submit as the user types. This is the *only* JS in the tip.

**`app/javascript/controllers/autosubmit_controller.js`**

```js
import { Controller } from "@hotwired/stimulus"
import debounce from 'debounce'

// Connects to data-controller="autosubmit"
export default class extends Controller {
  initialize() {
    this.debouncedSubmit = debounce(this.debouncedSubmit.bind(this), 300)
  }

  submit(e) {
    this.element.requestSubmit()
  }

  debouncedSubmit() {
    this.submit()
  }
}
```

2. The whole widget lives inside its own lazy-loaded Turbo Frame on the host page, so every write can just `redirect_to multiple_select_path` and the frame re-renders itself.

**`app/views/pages/kitchensink.html.erb`**

```erb
<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pt-20">
  <%= render "shared/divider", title: "Day 1/30 - Multiple Select" %>

  <div class="mx-auto max-w-md">
    <%= turbo_frame_tag "multiple_select", src: multiple_select_path %>
  </div>
</div>
```

3. Inside that frame sits the badge list, a `GET` search form targeting a **nested** `technologies` frame, and the results dropdown. Note `data: { turbo_frame: "technologies" }` on the form — the form itself is not reloaded, only the results list is. The `button_to`s target `multiple_select` so that adding/removing a favourite re-renders the badges *and* the search results together.

**`app/views/pages/multiple_select.html.erb`**

```erb
<%= turbo_frame_tag "multiple_select" do %>
  <div>
    <label for="combobox" class="block text-sm font-medium text-gray-700">What are your favourite technologies?</label>
    <div class="relative">
      <% if @favourites.any? %>
        <div class="flex flex-wrap mt-3">
          <% @favourites.each do |favourite| %>
            <span class="inline-flex items-center rounded-full bg-indigo-100 py-0.5 pl-2 pr-0.5 text-xs font-medium text-indigo-700">
              <%= favourite.name %>
              <%= button_to favourite_technology_path(favourite), class: "ml-0.5 inline-flex h-4 w-4 flex-shrink-0 items-center justify-center rounded-full text-indigo-400 hover:bg-indigo-200 hover:text-indigo-500 focus:bg-indigo-500 focus:text-white focus:outline-none", method: :delete do %>
                <span class="sr-only">Remove small option</span>
                <svg class="h-2 w-2" stroke="currentColor" fill="none" viewBox="0 0 8 8">
                  <path stroke-linecap="round" stroke-width="1.5" d="M1 1l6 6m0-6L1 7" />
                </svg>
              <% end %>
            </span>
          <% end %>
        </div>
      <% end %>
      <%= form_tag multiple_select_path, class: "relative mt-1", method: :get, data: {controller: "autosubmit", turbo_frame: "technologies"} do %>
        <input
          id="combobox"
          name="query"
          type="text"
          data-action="input->autosubmit#debouncedSubmit"
          class="w-full rounded-md border border-gray-300 bg-white py-2 pl-3 pr-12 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-1 focus:ring-indigo-500 sm:text-sm"
          role="combobox"
          aria-controls="options"
          aria-expanded="false">
        <button type="button" class="absolute inset-y-0 right-0 flex items-center rounded-r-md px-2 focus:outline-none">
          <svg class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path fill-rule="evenodd" d="M10 3a.75.75 0 01.55.24l3.25 3.5a.75.75 0 11-1.1 1.02L10 4.852 7.3 7.76a.75.75 0 01-1.1-1.02l3.25-3.5A.75.75 0 0110 3zm-3.76 9.2a.75.75 0 011.06.04l2.7 2.908 2.7-2.908a.75.75 0 111.1 1.02l-3.25 3.5a.75.75 0 01-1.1 0l-3.25-3.5a.75.75 0 01.04-1.06z" clip-rule="evenodd" />
          </svg>
        </button>
      <% end %>
      <%= turbo_frame_tag "technologies" do %>
        <% if params[:query].present? %>
          <ul class="absolute mt-1 z-10 max-h-60 w-full overflow-auto rounded-md bg-white py-1 text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm" id="options" role="listbox">
            <% @technologies.each do |technology| %>
              <li class="relative cursor-default select-none py-2 pl-3 pr-9 text-gray-900" role="option" tabindex="-1">
                <%= button_to technology.name,
                  favourite_technologies_path(favourite_technology: { technology_id: technology.id }),
                  class: "block truncate",
                  data: {turbo_frame: "multiple_select"} %>
              </li>
            <% end %>
            <% unless @technologies.any? %>
              <li class="relative cursor-default select-none py-2 pl-3 pr-9 text-gray-900" role="option" tabindex="-1">
                <%= button_to "Add #{params[:query]}", technologies_path(technology: { name: params[:query], favourite_technology_attributes: { touch: true } }), method: :post, class: "block truncate", data: {turbo_frame: "multiple_select"} %>
              </li>
            <% end %>
          </ul>
        <% end %>
      <% end %>
    </div>
  </div>
<% end %>
```

> In the first version of the thread these `button_to`s used `data: { turbo_frame: "_top" }` to break out of the frame entirely and repaint the page; the refactor replaced `_top` with the named outer frame so only the widget reloads. `_top` remains the escape hatch when a nested action needs to drive full-page navigation.

4. The search itself is a plain model scope — favourites are excluded so an already-picked technology never shows up again in results.

**`app/models/technology.rb`**

```ruby
class Technology < ApplicationRecord
  has_one :favourite_technology
  accepts_nested_attributes_for :favourite_technology, allow_destroy: true

  scope :by_name, -> (name) { where("name ILIKE ?", "%#{name}%") }

  def self.search(params)
    technologies = all
    technologies = technologies.by_name(params[:query]) if params[:query].present?
    technologies = technologies.where.not(id: FavouriteTechnology.pluck(:technology_id))

    technologies
  end
end
```

**`app/models/favourite_technology.rb`**

```ruby
class FavouriteTechnology < ApplicationRecord
  attr_accessor :touch

  belongs_to :technology
  delegate :name, to: :technology
end
```

5. Controllers are boring CRUD. The "Add <query>" button creates the technology *and* its favourite in one shot via `accepts_nested_attributes_for`.

**`app/controllers/pages_controller.rb`**

```ruby
class PagesController < ApplicationController
  def kitchensink
  end

  def multiple_select
    @technologies = Technology.search(params)
    @favourites = FavouriteTechnology.includes(:technology).all
  end
end
```

**`app/controllers/favourite_technologies_controller.rb`**

```ruby
class FavouriteTechnologiesController < ApplicationController
  def create
    @favourite_technology = FavouriteTechnology.new(favourite_technology_params)

    if @favourite_technology.save
      redirect_to multiple_select_path
    end
  end

  def destroy
    @favourite_technology = FavouriteTechnology.find(params[:id])
    @favourite_technology.destroy
    redirect_to multiple_select_path
  end

  private

  def favourite_technology_params
    params.require(:favourite_technology).permit(:technology_id)
  end
end
```

**`app/controllers/technologies_controller.rb`**

```ruby
class TechnologiesController < ApplicationController
  def create
    @technology = Technology.new(technology_params)

    if @technology.save
      redirect_to multiple_select_path
    end
  end

  private

  def technology_params
    params.require(:technology).permit(:name, favourite_technology_attributes: [:touch, :_destroy])
  end
end
```

**`config/routes.rb`**

```ruby
get 'multiple_select', to: 'pages#multiple_select'

resources :technologies, only: [:create]
resources :favourite_technologies, only: [:create, :destroy]
```

**Why it matters / when to use:** This is the canonical replacement for a React `react-select`/combobox: type-ahead multi-select with create-on-the-fly, built from a GET form, two nested frames and ~15 lines of JS. The `autosubmit` controller introduced here is reused in at least six later tips.

`Pattern:` turbo-frames, lazy-frames, stimulus, autosubmit, forms, search-filter

---

## Day 2 — Realtime online users with Turbo broadcasts

**Source:** https://x.com/itsameandrea/status/1627674208070402048  ·  **Date:** 2023-02-20  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/aaea43adb959b6239026928e695def9a1e2f3f81 (plus refactor `0c46ac8`)

A live "who's online" panel: log in from a third browser and their card appears for everyone instantly; close the tab and it disappears. The trick is that you don't need a presence gem or a heartbeat — you *subclass `Turbo::StreamsChannel`* and hook the ActionCable `subscribed` / `unsubscribed` lifecycle callbacks, storing the online set in a Redis set and broadcasting an append/remove Turbo Stream from the User model.

### How it works

1. Identify the connection so `current_user` is available inside the channel. With Devise, read the user out of Warden.

**`app/channels/application_cable/connection.rb`**

```ruby
module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      self.current_user = find_verified_user
    end

    protected

    def find_verified_user
      if current_user = env['warden'].user
        current_user
      else
        reject_unauthorized_connection
      end
    end
  end
end
```

2. Extend Turbo's own streams channel. `subscribed`/`unsubscribed` fire exactly when a browser tab opens or closes the socket, which is the definition of "online". `super` keeps all the normal Turbo Stream behaviour intact.

**`app/channels/online_channel.rb`**

```ruby
class OnlineChannel < Turbo::StreamsChannel
  def subscribed
    super
    ActionCable.server.pubsub.redis_connection_for_subscriptions.sadd "online_users", current_user.id
    current_user.broadcast_online
  end

  def unsubscribed
    super
    ActionCable.server.pubsub.redis_connection_for_subscriptions.srem "online_users", current_user.id
    current_user.broadcast_offline
  end
end
```

3. The User model owns the broadcasts and the `online` scope that reads the Redis set.

**`app/models/user.rb`**

```ruby
class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  def self.online
    ids = ActionCable.server.pubsub.redis_connection_for_subscriptions.smembers("online_users")
    where(id: ids)
  end

  def broadcast_online
    broadcast_append_to "online_users", target: "online_users",
      partial: 'users/card',
      locals: { user: self }
  end

  def broadcast_offline
    broadcast_remove_to "online_users", target: "user_#{id}"
  end
end
```

4. Open the socket with `turbo_stream_from`, passing the custom `channel:`. The final refactor moves the whole panel into its own lazy-loaded frame so users already online *before* you connected are rendered on load.

**`app/views/pages/online_users.html.erb`**

```erb
<%= turbo_frame_tag "online_users_frame" do %>
  <%= turbo_stream_from "online_users", channel: OnlineChannel %>

  <div id="online_users" class="grid grid-cols-1 gap-4 sm:grid-cols-2">
    <% @online_users.each do |user| %>
      <%= render 'users/card', user: user %>
    <% end %>
  </div>
<% end %>
```

**`app/views/pages/kitchensink.html.erb`** (host page)

```erb
<%= render "shared/divider", title: "Day 2/30 - Online users" %>

<div class="mx-auto max-w-2xl my-20">
  <%= turbo_frame_tag "online_users_frame", src: online_users_path %>
</div>
```

5. The card partial's `dom_id(user)` is what `broadcast_remove_to ... target: "user_#{id}"` targets.

**`app/views/users/_card.html.erb`**

```erb
<div
  id="<%= dom_id(user) %>"
  class="relative flex items-center space-x-3 rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2 hover:border-gray-400">
  <div class="flex-shrink-0">
    <%= image_tag "#{user.username}.jpeg", class: "h-10 w-10 rounded-full object-cover" %>
  </div>
  <div class="min-w-0 flex-1">
    <a href="#" class="focus:outline-none">
      <span class="absolute inset-0" aria-hidden="true"></span>
      <p class="text-sm font-medium text-gray-900"><%= user.username %></p>
      <p class="truncate text-sm text-gray-500"><%= user.email %></p>
    </a>
  </div>
</div>
```

**`app/controllers/pages_controller.rb`**

```ruby
def online_users
  @online_users = User.online
end
```

**`config/routes.rb`**

```ruby
get 'online_users', to: 'pages#online_users'
```

**Why it matters / when to use:** Presence indicators, "N people viewing", collaborative cursors — anything where connect/disconnect *is* the event. Subclassing `Turbo::StreamsChannel` is the general escape hatch for running server code on socket lifecycle without abandoning Turbo's broadcast machinery.

`Pattern:` turbo-streams, broadcasts, actioncable, turbo-frames, lazy-frames

---

## Day 3 — Animating Turbo Stream appends and removals

**Source:** https://x.com/itsameandrea/status/1628032757782945792  ·  **Date:** 2023-02-21  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/ce097fd2f0a4a5557d2ed8bde4914993b9df27d0

Turbo Streams normally snap elements in and out of the DOM with no transition. This tip intercepts the `turbo:before-stream-render` event in a Stimulus controller and drives animations declaratively from two data attributes on the element itself: `data-entering-class` and `data-leaving-class`. The genuinely clever part is the **remove** case — the controller calls `event.preventDefault()` to stop Turbo removing the node, plays the leaving animation, and only calls `event.target.performAction()` once `animationend` fires.

### How it works

1. A single controller listens for the stream event and reads the classes off the incoming/outgoing element.

**`app/javascript/controllers/stream_animations_controller.js`**

```js
import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.setupEventListener()
  }

  setupEventListener() {
    document.addEventListener("turbo:before-stream-render", (event) => {
      const turboStreamElement = event.target
      const {action, target} = turboStreamElement
      const template = turboStreamElement.firstElementChild

      // <turbo-stream action="append" target="some_id">
      if (action === 'append') {
        const {enteringClass} = template.content.firstElementChild.dataset

        if (enteringClass) {
          template.content.firstElementChild.classList.add(enteringClass)
        }
      }

      // <turbo-stream action="remove" target="some_id">
      if (action === "remove") {
        const targetToRemove = document.getElementById(target)
        const {leavingClass} = targetToRemove.dataset

        if (leavingClass) {
          event.preventDefault()
          targetToRemove.classList.add(leavingClass)
          targetToRemove.addEventListener("animationend", () => {
            event.target.performAction()
          })
        }
      }
    })
  }
}
```

2. Register it and mount it on the container that receives streams. (Andrea notes the listener could live in `application.js`, but keeping it in a controller means pages that don't want animations never run it.)

**`app/javascript/controllers/index.js`**

```js
import StreamAnimationsController from "./stream_animations_controller"
application.register("stream-animations", StreamAnimationsController)
```

**`app/views/pages/online_users.html.erb`**

```erb
<%= turbo_frame_tag "online_users_frame" do %>
  <%= turbo_stream_from "online_users", channel: OnlineChannel %>

  <div id="online_users" class="grid grid-cols-1 gap-4 sm:grid-cols-2" data-controller="stream-animations">
    <% @online_users.each do |user| %>
      <%= render 'users/card', user: user %>
    <% end %>
  </div>
<% end %>
```

3. Individual elements opt in by declaring their animation classes. Here `animate.css` is pulled in from a CDN; any custom CSS animation works the same way, as long as it fires `animationend`.

**`app/views/users/_card.html.erb`**

```erb
<div
  id="<%= dom_id(user) %>"
  class="relative flex items-center space-x-3 rounded-lg border border-gray-300 bg-white px-6 py-5 shadow-sm focus-within:ring-2 focus-within:ring-indigo-500 focus-within:ring-offset-2 hover:border-gray-400 animate__animated"
  data-entering-class="animate__fadeInUp"
  data-leaving-class="animate__fadeOutDown">
  ...
</div>
```

**`app/views/layouts/application.html.erb`**

```erb
<link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/animate.css/4.1.1/animate.min.css" />
```

**Why it matters / when to use:** This is the reusable answer to "Turbo Streams feel janky". Drop the controller in once, then any partial can declare its own enter/leave animation with two data attributes. `preventDefault()` + `performAction()` is the general recipe for *deferring* any Turbo Stream action.

`Pattern:` turbo-streams, stimulus, animation

---

## Day 4 — JS-less modals with Turbo Frames

**Source:** https://x.com/itsameandrea/status/1628389637495607297  ·  **Date:** 2023-02-22  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/706a547

Modals are the use case Andrea says he *always* reached for a Stimulus controller for. With Turbo you don't need one at all: put an empty `turbo_frame_tag "modal"` in the application layout, have any link target that frame, and render the modal markup wrapped in a matching frame from the server. Opening a modal becomes an ordinary GET request; closing it is a link with `data-turbo-frame="_top"`.

### How it works

1. Declare an empty modal frame once, in the layout. It renders nothing until something fills it.

**`app/views/layouts/application.html.erb`**

```erb
<body>
  <%= render 'shared/flash' %>

  <%= yield %>

  <%= turbo_frame_tag "modal" %>
</body>
```

2. Any link anywhere in the app opens the modal by targeting that frame.

**`app/views/pages/kitchensink.html.erb`**

```erb
<%= render "shared/divider", title: "Day 4/30 - JS-less modals" %>

<div class="mx-auto max-w-2xl my-20 flex items-center justify-center">
  <%= link_to "Open Modal", modal_path, data: {turbo_frame: "modal"}, class: "bg-indigo-500 text-white rounded px-3 py-2" %>
</div>
```

3. The server response wraps the modal markup in a frame with the **same id**, so Turbo swaps it into the layout's placeholder. Closing is just a link that breaks out of the frame with `_top`, which triggers a full-page visit and therefore empties the modal frame again.

**`app/views/pages/modal.html.erb`**

```erb
<%= turbo_frame_tag "modal" do %>
  <div class="relative z-10" aria-labelledby="modal-title" role="dialog" aria-modal="true">
    <div class="fixed inset-0 bg-gray-500 bg-opacity-75 transition-opacity"></div>
      <div class="fixed inset-0 z-10 overflow-y-auto">
        <div class="flex min-h-full items-end justify-center p-4 text-center sm:items-center sm:p-0">
          <div class="relative transform overflow-hidden rounded-lg bg-white px-4 pt-5 pb-4 text-left shadow-xl transition-all sm:my-8 sm:w-full sm:max-w-sm sm:p-6">
            <div>
              <div class="mx-auto flex h-12 w-12 items-center justify-center rounded-full bg-green-100">
                <svg class="h-6 w-6 text-green-600" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M4.5 12.75l6 6 9-13.5" />
                </svg>
              </div>
              <div class="mt-3 text-center sm:mt-5">
                <h3 class="text-lg font-medium leading-6 text-gray-900" id="modal-title">Payment successful</h3>
                <div class="mt-2">
                  <p class="text-sm text-gray-500">Lorem ipsum dolor sit amet consectetur adipisicing elit. Consequatur amet labore.</p>
                </div>
              </div>
            </div>
            <div class="mt-5 sm:mt-6">
              <%= link_to "Go back to dashboard", root_path, data: { turbo_frame: "_top" }, class: "inline-flex w-full justify-center rounded-md border border-transparent bg-indigo-600 px-4 py-2 text-base font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2 sm:text-sm" %>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
<% end %>
```

**`app/controllers/pages_controller.rb`**

```ruby
def modal
end
```

**`config/routes.rb`**

```ruby
get 'modal', to: 'pages#modal'
```

4. Andrea closes by pointing out that frames emit their own lifecycle events, so the Day 3 animation trick applies here too. From the Turbo docs he quoted:

> `turbo:before-frame-render` fires before rendering the `<turbo-frame>` element. Access the new `<turbo-frame>` element with `event.detail.newFrame`. Rendering can be canceled and continued with `event.detail.resume` (see *Pausing Rendering*). Customize how Turbo Drive renders the response by overriding the `event.detail.render` function (see *Custom Rendering*).

**Why it matters / when to use:** Every modal in an app becomes a normal route with a normal view — bookmarkable, testable, server-rendered, no client state. Use `data-turbo-frame="modal"` on links/buttons to open, `_top` to dismiss. This is the base pattern for edit-in-modal, confirm-in-modal, wizard steps, etc.

`Pattern:` turbo-frames, modals

---

## Day 5 — Infinite scroll in under 5 minutes

**Source:** https://x.com/itsameandrea/status/1628765457464569857  ·  **Date:** 2023-02-23  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/96ebf6bf45e35577b39d4df3ef528b4cbd33ca76

Zero JavaScript infinite scroll. A **lazy-loaded** Turbo Frame sits at the bottom of the list; when it scrolls into view Turbo fetches it, and because the frame's `src` asks for `format: :turbo_stream`, the response both appends the next page of records to the list *and* replaces the sentinel frame with a new one pointing at page N+1. The frame chases itself down the page until `pagy.next` is nil. Uses the `pagy` gem (`pagy_countless` avoids the COUNT query entirely).

### How it works

1. Add pagy and enable the countless extra.

**`Gemfile`**

```ruby
gem "faker", "~> 3.1"

gem "pagy", "~> 6.0"
```

**`config/initializers/pagy.rb`**

```ruby
require 'pagy/extras/countless'
```

**`app/helpers/application_helper.rb`**

```ruby
module ApplicationHelper
  include Pagy::Frontend
end
```

2. The index action paginates and responds to *both* HTML (first load) and turbo_stream (every subsequent frame fetch).

**`app/controllers/tweets_controller.rb`**

```ruby
class TweetsController < ApplicationController
  include Pagy::Backend
  before_action :set_tweet, only: %i[ show edit update destroy ]

  # GET /tweets
  def index
    @pagy, @tweets = pagy_countless(Tweet.all, items: 25)

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  # ... standard scaffold show/new/edit/create/update/destroy ...

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_tweet
      @tweet = Tweet.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def tweet_params
      params.fetch(:tweet, {})
    end
end
```

3. The index page is an **empty** `<ul>` plus the sentinel frame for page 1.

**`app/views/tweets/index.html.erb`**

```erb
<div class="mx-auto max-w-7xl px-4 sm:px-6 lg:px-8 pt-5">
  <div class="mx-auto max-w-2xl mt-5 flex items-center justify-center">
    <ul id="tweets" role="list" class="divide-y divide-gray-200">
    </ul>
    <%= render 'tweets/scroll_frame', page: 1 %>
  </div>
</div>
```

4. The sentinel is a lazy frame that explicitly requests a Turbo Stream response. `loading: :lazy` is what makes it fire on scroll-into-view.

**`app/views/tweets/_scroll_frame.html.erb`**

```erb
<%= turbo_frame_tag "infinite_scroll",
  src: tweets_path(page: page, format: :turbo_stream), loading: :lazy %>
```

5. The stream template does the two-step: append records, then move the sentinel forward. Omitting the replace when there's no next page ends the chain.

**`app/views/tweets/index.turbo_stream.erb`**

```erb
<%= turbo_stream.append "tweets", partial: "tweets/tweets", locals: { tweets: @tweets } %>

<% if @pagy.next.present? %>
  <%= turbo_stream.replace "infinite_scroll",
    partial: "tweets/scroll_frame",
    locals: { page: @pagy.next } %>
<% end %>
```

**`app/views/tweets/_tweets.html.erb`**

```erb
<%= render partial: "tweets/tweet", collection: tweets %>
```

**`app/views/tweets/_tweet.html.erb`**

```erb
<li id="<%= dom_id(tweet) %>" class="relative bg-white py-5 px-4 focus-within:ring-2 focus-within:ring-inset focus-within:ring-indigo-600 hover:bg-gray-50">
  <div class="flex justify-between space-x-3">
    <div class="min-w-0 flex-1 flex items-center">
      <div class="flex-shrink-0">
        <img class="h-12 w-12 rounded-full" src="<%= Faker::LoremFlickr.image(size: "100x100", search_terms: ['star wars']) %>" alt="">
      </div>
      <div class="min-w-0 flex-1 ml-2">
        <p class="truncate text-sm font-medium text-gray-900"><%= tweet.handle %></p>
      </div>
    </div>
    <time datetime="2021-01-27T16:35" class="flex-shrink-0 whitespace-nowrap text-sm text-gray-500">1d ago</time>
  </div>
  <div class="mt-1">
    <p class="text-sm text-gray-600 line-clamp-2">
      <%= tweet.content %>
    </p>
  </div>
</li>
```

**Why it matters / when to use:** The self-replacing lazy frame is the single most reusable Hotwire idiom in the whole series — infinite feeds, "load more" buttons, progressive table loading. No IntersectionObserver, no scroll listener, no JS at all.

`Pattern:` turbo-frames, lazy-frames, turbo-streams, pagination

---

## Day 6 — Dynamic nested forms

**Source:** https://x.com/itsameandrea/status/1629137697305657345  ·  **Date:** 2023-02-24  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/d8860cecf2eea6e010e4afa39f1aed3838892b44

A `Recipe` has many `Ingredient`s, and the ingredients fieldset needs to grow and shrink dynamically as the user adds or removes ingredients — the classic "cocoon-style" nested form, but built with Turbo Streams instead of a JS gem. A small Stimulus controller fires `request.js` GET/DELETE calls to two thin server actions that respond with `turbo_stream.append` and `turbo_stream.replace`, which insert a freshly rendered ingredient partial or swap an existing one in place. Because the partial itself renders hidden `_destroy` and `id` fields understood by `accepts_nested_attributes_for`, the whole thing composes with Rails' native nested-attributes handling — no client-side form state to manage at all.

### How it works

1. The `Recipe` model accepts nested attributes for its ingredients, with `reject_if: :all_blank` so blank rows are dropped, and `allow_destroy: true` so a hidden `_destroy` flag is enough to remove one on save.

**`app/models/recipe.rb`**
```ruby
class Recipe < ApplicationRecord
  has_many :ingredients, dependent: :destroy
  accepts_nested_attributes_for :ingredients, allow_destroy: true, reject_if: :all_blank
end
```

**`app/models/ingredient.rb`**
```ruby
class Ingredient < ApplicationRecord
  belongs_to :recipe
end
```

2. `RecipesController` is a standard CRUD controller. `new` seeds the form with one blank ingredient so there's always at least one row to render; `recipe_params` permits `ingredients_attributes` with `:id`, `:name`, `:_destroy`.

**`app/controllers/recipes_controller.rb`**
```ruby
class RecipesController < ApplicationController
  def new
    @recipe = Recipe.new(ingredients: [Ingredient.new])
  end

  def create
    @recipe = Recipe.new(recipe_params)

    if @recipe.save
      redirect_to root_path, notice: "Recipe was successfully created."
    end
  end

  def index
    @recipes = Recipe.all
  end

  def edit
    @recipe = Recipe.includes(:ingredients).find(params[:id])
  end

  def update
    @recipe = Recipe.find(params[:id])

    if @recipe.update(recipe_params)
      redirect_to root_path, notice: "Recipe was successfully created."
    end
  end

  private

  def recipe_params
    params.require(:recipe).permit(:name, ingredients_attributes: [:id, :name, :_destroy])
  end
end
```

3. The recipe form wraps the ingredients list in a `streams` Stimulus controller. Its `url` value points at the "new nested ingredient" turbo_stream endpoint, and the ➕ button just calls `streams#getRequest` — no target url per-click, it's all declared in the data attribute.

**`app/views/recipes/_form.html.erb`**
```erb
<%= form_with model: recipe do |form| %>
  <div
    class="shadow sm:overflow-hidden sm:rounded-md"
    data-controller="streams"
    data-streams-url-value="<%= new_nested_ingredient_path(format: :turbo_stream) %>">
    <div class="space-y-6 bg-white px-4 py-5 sm:p-6">
      <div class="grid grid-cols-3 gap-6">
        <div class="col-span-3 sm:col-span-2">
          <%= form.label :name, class: "block text-sm font-medium text-gray-700" %>
          <div class="mt-1 flex rounded-md shadow-sm">
            <%= form.text_field :name, class: "block w-full flex-1 rounded-md border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm", placeholder: "Carbonara" %>
          </div>
        </div>
      </div>

      <div class="relative">
        <div class="absolute inset-0 flex items-center" aria-hidden="true">
          <div class="w-full border-t border-gray-300"></div>
        </div>
        <div class="relative flex justify-start">
          <span class="bg-white pr-2 text-sm text-gray-500">Ingredients</span>
        </div>
      </div>

      <div id="ingredients" class="space-y-3" data-streams-target="container">
        <% recipe.ingredients.each do |ingredient| %>
          <%= render "recipes/ingredient_fields", ingredient: ingredient %>
        <% end %>
      </div>

      <div class="relative">
        <div class="absolute inset-0 flex items-center" aria-hidden="true">
          <div class="w-full border-t border-gray-300"></div>
        </div>
        <div class="relative flex justify-center">
          <button type="button" class="bg-white px-2 text-gray-500" data-action="streams#getRequest">
            <svg class="h-5 w-5 text-gray-500" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path d="M10.75 4.75a.75.75 0 00-1.5 0v4.5h-4.5a.75.75 0 000 1.5h4.5v4.5a.75.75 0 001.5 0v-4.5h4.5a.75.75 0 000-1.5h-4.5v-4.5z" />
            </svg>
          </button>
        </div>
      </div>
    </div>
    <div class="bg-gray-50 px-4 py-3 text-right sm:px-6">
      <button type="submit" class="inline-flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2">Save</button>
    </div>
  </div>
<% end %>
```

4. The `streams` Stimulus controller is deliberately generic and reusable: it just holds a `url` value and fires a GET or DELETE at it using `@rails/request.js`. The server decides what turbo_stream comes back.

**`app/javascript/controllers/streams_controller.js`**
```js
import { Controller } from "@hotwired/stimulus"
import { get, destroy } from "@rails/request.js"

// Connects to data-controller="streams"
export default class extends Controller {
  static values = { url: String }
  static targets = [ "container" ]

  async getRequest() {
    await get(this.urlValue)
  }

  async destroyRequest() {
    await destroy(this.urlValue)
  }
}
```

**`app/javascript/controllers/index.js`** (registration, added lines)
```js
import StreamsController from "./streams_controller"
application.register("streams", StreamsController)
```

5. Each ingredient row is its own `_ingredient_fields` partial. Since a brand-new ingredient has no `id` yet, `Time.now.to_i` is used as a temporary identifier so `fields_for` still gets a unique index and the row still has its own DOM id to target with Turbo Streams. The row wraps itself in its own `streams` controller instance pointed at its own destroy URL, and only renders the remove button if the ingredient is persisted or was just added via the ➕ button.

**`app/views/recipes/_ingredient_fields.html.erb`**
```erb
<% id = ingredient.id || Time.now.to_i %>

<div id="ingredient_<%= id %>">
  <%= fields_for "recipe[ingredients_attributes][#{id}]", ingredient do |form| %>
    <%= form.hidden_field :id %>
    <%= form.hidden_field :_destroy, value: local_assigns[:destroy] || false %>

    <% unless local_assigns[:destroy] %>
      <div
        class="grid grid-cols-3 gap-6"
        data-controller="streams"
        data-streams-url-value="<%= nested_ingredient_path(id, format: :turbo_stream) %>">
        <div class="col-span-3">
          <div class="flex rounded-md shadow-sm relative">
            <%= form.text_field :name, class: "block w-full flex-1 rounded-md border-gray-300 focus:border-indigo-500 focus:ring-indigo-500 sm:text-sm", placeholder: "Eggs" %>
            <% if local_assigns[:allow_remove] || ingredient.persisted? %>
              <button data-action="streams#destroyRequest" type="button" class="bg-red-100 absolute w-10 border border-gray-300 rounded-r-md right-0 top-0 bottom-0 flex items-center justify-center">
                <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4">
                  <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
                </svg>
              </button>
            <% end %>
          </div>
        </div>
      </div>
    <% end %>
  <% end %>
</div>
```

6. Clicking ➕ calls `streams#getRequest`, hitting `NestedIngredientsController#new`, which responds with a turbo_stream that appends a brand new `_ingredient_fields` partial (with `allow_remove: true` so its delete button shows immediately, even though it isn't persisted).

**`app/controllers/nested_ingredients_controller.rb`**
```ruby
class NestedIngredientsController < ApplicationController
  def new
    @ingredient = Ingredient.new

    respond_to do |format|
      format.turbo_stream
    end
  end

  def destroy
    @id = params[:id]
    @ingredient = Ingredient.find_by(id: params[:id])

    respond_to do |format|
      format.turbo_stream
    end
  end
end
```

**`app/views/nested_ingredients/new.turbo_stream.erb`**
```erb
<%= turbo_stream.append "ingredients",
  partial: "recipes/ingredient_fields",
  locals: { ingredient: @ingredient, allow_remove: true } %>
```

7. Clicking the row's remove button calls `streams#destroyRequest`, which sends a DELETE to `NestedIngredientsController#destroy`. Note this doesn't delete anything from the DB — it looks the ingredient up by id (which may be the fake `Time.now` id and thus find nothing), then replaces the row with the same partial rendered with `destroy: true`, which sets the hidden `_destroy` field to `true`. The row disappears from view, but a hidden `_destroy=true` field for that `ingredients_attributes` index still submits with the form, so Rails' nested-attributes handling deletes the real record (if any) on save.

**`app/views/nested_ingredients/destroy.turbo_stream.erb`**
```erb
<%= turbo_stream.replace "ingredient_#{@id}",
  partial: "recipes/ingredient_fields",
  locals: { ingredient: @ingredient, destroy: true } %>
```

A separate `IngredientsController#destroy` exists as a conventional hard-delete route (`DELETE /ingredients/:id`), independent of the soft-destroy toggle used inline in the form:

**`app/controllers/ingredients_controller.rb`**
```ruby
class IngredientsController < ApplicationController
  def destroy
    @ingredient = Ingredient.find(params[:id])

    respond_to do |format|
      if @ingredient.destroy 
        format.turbo_stream
      end
    end
  end
end
```

8. The recipes index is rendered inside a lazily-loaded turbo frame on the kitchen-sink demo page, and routes wire everything up.

**`app/views/recipes/index.html.erb`** (table, wrapped in its own frame)
```erb
<%= turbo_frame_tag "recipes_table", class: "w-full" do %>
  <div class="px-4 sm:px-6 lg:px-8">
    <div class="sm:flex sm:items-center">
      <div class="sm:flex-auto">
        <h1 class="text-base font-semibold leading-6 text-gray-900">Recipes 👩‍🍳</h1>
        <p class="mt-2 text-sm text-gray-700">A list of all your tasty recipes.</p>
      </div>
      <div class="mt-4 sm:mt-0 sm:ml-16 sm:flex-none">
        <%= link_to "Add Recipe", new_recipe_path, class: "block rounded-md bg-indigo-600 py-1.5 px-3 text-center text-sm font-semibold leading-6 text-white shadow-sm hover:bg-indigo-500 focus-visible:outline focus-visible:outline-2 focus-visible:outline-offset-2 focus-visible:outline-indigo-600", data: { turbo_frame: "_top" } %>
      </div>
    </div>
    <div class="mt-8 flow-root">
      <div class="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
          <table class="min-w-full divide-y divide-gray-300">
            <thead>
              <tr>
                <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Name</th>
                <th scope="col" class="relative py-3.5 pl-3 pr-4 sm:pr-0">
                  <span class="sr-only">Add Recipe</span>
                </th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <% @recipes.each do |recipe| %>
                <tr>
                  <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0"><%= recipe.name %></td>
                  <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                    <%= link_to "Edit", edit_recipe_path(recipe), class: "text-indigo-600 hover:text-indigo-900" %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
<% end %>
```

**`config/routes.rb`** (additions)
```ruby
resources :recipes, except: [:destroy]
resources :ingredients, only: [:destroy]
resources :nested_ingredients, only: [:new, :destroy]
```

**Why it matters / when to use:** This replaces a JS nested-form gem like cocoon with ~15 lines of Stimulus plus two tiny turbo_stream-only controller actions, while still relying entirely on Rails' built-in `accepts_nested_attributes_for`/`_destroy` mechanism for persistence — nothing about the save path changes.

`Pattern:` nested-forms, turbo-streams, turbo-frames, lazy-frames, stimulus, stimulus-values, stimulus-targets, forms

---

## Day 7 — (Almost) JS-less table filters

**Source:** https://x.com/itsameandrea/status/1629517063571279872  ·  **Date:** 2023-02-25  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/852decf8eb3fc02bc968652f2f3043dadf29a5e9

A common table-with-filters UI — text search plus checkbox dropdowns — gets built with almost no hand-written JS. The filter form sits above a turbo frame that wraps only the results table, and is itself connected to that inner frame via `data-turbo-frame`, so submitting the form re-renders just the table, not the surrounding filter controls. An `autosubmit` Stimulus controller submits the form automatically on input/change (debounced for text, immediate for checkboxes), and all the actual filtering logic lives in plain ActiveRecord scopes on the model — exactly the Ruby you'd write anyway, just triggered a bit more eagerly.

### How it works

1. `CharactersController#index` delegates all filtering to a `Character.search` class method, keeping the controller itself trivial. It also collects the distinct values for each filterable column to populate the dropdowns.

**`app/controllers/characters_controller.rb`**
```ruby
class CharactersController < ApplicationController
  def index
    @characters = Character.search(params)

    @species = Character.pluck(:species).uniq
    @homeworlds = Character.pluck(:homeworld).uniq
    @affiliations = Character.pluck(:affiliation).uniq
  end
end
```

2. The model defines one scope per filterable column, and `self.search` conditionally chains them based on which params are present. Nothing here is Hotwire-specific — it's just composable ActiveRecord.

**`app/models/character.rb`**
```ruby
class Character < ApplicationRecord
  scope :by_name, -> (name) { where('name ILIKE ?', "%#{name}%") }
  scope :by_species, -> (species) { where species: species }
  scope :by_homeworld, -> (homeworld) { where homeworld: homeworld }
  scope :by_affiliation, -> (affiliation) { where affiliation: affiliation }

  def self.search(params)
    characters = where(nil)

    characters = characters.by_name(params[:name]) if params[:name].present?
    characters = characters.by_species(params[:species]) if params[:species].present?
    characters = characters.by_homeworld(params[:homeworlds]) if params[:homeworlds].present?
    characters = characters.by_affiliation(params[:affiliations]) if params[:affiliations].present?

    characters
  end
end
```

3. The view has two nested turbo frames: an outer `characters` frame holding the whole page section, and an inner `characters_table` frame holding just the `<table>`. The filter `form_with` is submitted with GET, targets `data-turbo-frame: 'characters_table'` so the response only replaces the table, and is controlled by `autosubmit` so every keystroke/checkbox toggle re-submits. The text field debounces via `autosubmit#debouncedSubmit`; checkboxes submit immediately via `autosubmit#submit`.

**`app/views/characters/index.html.erb`**
```erb
<%= turbo_frame_tag "characters", class: "w-full" do %>
  <div class="px-4 sm:px-6 lg:px-8 py-8">
    <div class="sm:flex sm:items-center">
      <div class="sm:flex-auto">
        <h1 class="text-base font-semibold leading-6 text-gray-900">Star wars characters 🛸</h1>
      </div>
    </div>
    
    <div class="flex flex-col space-y-8 my-8">
      <%= form_with url: characters_path,
        method: :get,
        class: 'flex space-x-10',
        data: {controller: 'autosubmit', turbo_frame: 'characters_table'} do |f| %>
        <div class="flex flex-col">
          <div>
            <%= f.text_field "name",
              placeholder: "Search through the galaxy",
              value: params[:name],
              data: {action: "input->autosubmit#debouncedSubmit"},
              class: "border border-gray-300 rounded-md shadow-sm py-2 px-3 focus:outline-none w-[320px] focus:ring-orange focus:border-orange sm:text-sm" %>
          </div>

          <div class="flex space-x-5 mt-8">
            <div class="relative" data-controller="dropdown">
                <!-- Expand/collapse question button -->
              <button data-action="click->dropdown#toggle click@window->dropdown#hide" data-dropdown-target="button" type="button" class="group inline-flex items-center justify-center text-sm font-medium text-gray-700 hover:text-gray-900" aria-controls="filter-section-1" aria-expanded="false">
                <span class="font-medium text-gray-900 text-base"> Species </span>
                <svg class="flex-shrink-0 -mr-1 ml-1 h-5 w-5 text-gray-400 group-hover:text-gray-500" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"></path>
                </svg>
              </button>
              <div class="py-6 absolute left-0 max-h-64 overflow-auto mt-2 hidden bg-white z-200 min-w-full rounded-md shadow-2xl" data-dropdown-target="menu">
                <div class="space-y-6 pl-4">
                  <% @species.each do |specie| %>
                    <label class="flex items-center justify-start mr-4 cursor-pointer">
                      <%= f.check_box('species[]', {data: {action: 'autosubmit#submit' }}, checked: params[:species]&.include?(specie.to_s), class: 'h-4 w-4 border-gray-300 rounded text-indigo-600 focus:ring-indigo-500'}, specie, nil) %>
                      <span class="ml-3 text-sm text-gray-700 flex-nowrap whitespace-nowrap" data-action="click->join-classes#checkAdjacentFilter click->auto-submit#submit"><%= specie.to_s.gsub('_', ' ').capitalize %></span>
                    </label>
                  <% end %>
                </div>
              </div>
            </div>

            <div class="relative" data-controller="dropdown">
                <!-- Expand/collapse question button -->
              <button data-action="click->dropdown#toggle click@window->dropdown#hide" data-dropdown-target="button" type="button" class="group inline-flex items-center justify-center text-sm font-medium text-gray-700 hover:text-gray-900" aria-controls="filter-section-1" aria-expanded="false">
                <span class="font-medium text-gray-900 text-base"> Home World </span>
                <svg class="flex-shrink-0 -mr-1 ml-1 h-5 w-5 text-gray-400 group-hover:text-gray-500" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"></path>
                </svg>
              </button>
              <div class="py-6 absolute left-0 max-h-64 overflow-auto mt-2 hidden bg-white z-200 min-w-full rounded-md shadow-2xl" data-dropdown-target="menu">
                <div class="space-y-6 pl-4">
                  <% @homeworlds.each do |homeworld| %>
                    <label class="flex items-center justify-start mr-4 cursor-pointer">
                      <%= f.check_box('homeworlds[]', {data: {action: 'autosubmit#submit', 'form-target': 'checkbox'}, checked: params[:homeworlds]&.include?(homeworld.to_s), class: 'h-4 w-4 border-gray-300 rounded text-indigo-600 focus:ring-indigo-500'}, homeworld, nil) %>
                      <span class="ml-3 text-sm text-gray-700 flex-nowrap whitespace-nowrap" data-action="click->join-classes#checkAdjacentFilter click->auto-submit#submit"><%= homeworld.to_s.gsub('_', ' ').capitalize %></span>
                    </label>
                  <% end %>
                </div>
              </div>
            </div>

            <div class="relative" data-controller="dropdown">
              <!-- Expand/collapse question button -->
              <button data-action="click->dropdown#toggle click@window->dropdown#hide" data-dropdown-target="button" type="button" class="group inline-flex items-center justify-center text-sm font-medium text-gray-700 hover:text-gray-900" aria-controls="filter-section-1" aria-expanded="false">
                <span class="font-medium text-gray-900 text-base"> Affiliation </span>
                <svg class="flex-shrink-0 -mr-1 ml-1 h-5 w-5 text-gray-400 group-hover:text-gray-500" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
                  <path fill-rule="evenodd" d="M5.293 7.293a1 1 0 011.414 0L10 10.586l3.293-3.293a1 1 0 111.414 1.414l-4 4a1 1 0 01-1.414 0l-4-4a1 1 0 010-1.414z" clip-rule="evenodd"></path>
                </svg>
              </button>
              <div class="py-6 absolute left-0 max-h-64 overflow-auto mt-2 hidden bg-white z-200 min-w-full rounded-md shadow-2xl" data-dropdown-target="menu">
                <div class="space-y-6 pl-4">
                  <% @affiliations.each do |affiliation| %>
                    <label class="flex items-center justify-start mr-4 cursor-pointer">
                      <%= f.check_box('affiliations[]', {data: {action: 'autosubmit#submit', 'form-target': 'checkbox'}, checked: params[:affiliations]&.include?(affiliation.to_s), class: 'h-4 w-4 border-gray-300 rounded text-indigo-600 focus:ring-indigo-500'}, affiliation, nil) %>
                      <span class="ml-3 text-sm text-gray-700 flex-nowrap whitespace-nowrap" data-action="click->join-classes#checkAdjacentFilter click->auto-submit#submit"><%= affiliation.to_s.gsub('_', ' ').capitalize %></span>
                    </label>
                  <% end %>
                </div>
              </div>
            </div>

            <div class="relative flex items-center" data-controller="loading">
              <%= link_to "Clear", characters_path, class: 'text-gray-500 text-xs', data: { turbo_frame: 'characters' } %>
              <svg class="hidden absolute animate-spin -mr-6 right-0 h-3 w-3" data-form-target="spinner" data-loading-target="spinner" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                <circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle>
                <path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
              </svg>
            </div>
          </div>
        </div>
      <% end %>
    </div>

    <%= turbo_frame_tag "characters_table" do %>
      <div class="flow-root">
        <div class="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
          <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
            <table class="min-w-full divide-y divide-gray-300">
              <thead>
                <tr>
                  <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Image</th>
                  <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Name</th>
                  <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Species</th>
                  <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Homeworld</th>
                  <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Affiliation</th>
                </tr>
              </thead>
              <tbody class="divide-y divide-gray-200">
                <% @characters.each do |character| %>
                  <tr>
                    <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                      <img class="inline-block h-14 w-14 rounded-md object-cover" src="<%= character.image_url %>" alt="">
                    </td>
                    <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                      <%= character.name %>
                    </td>
                    <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                      <%= character.species %>
                    </td>
                    <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                      <%= character.homeworld %>
                    </td>
                    <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                      <%= character.affiliation %>
                    </td>
                  </tr>
                <% end %>
              </tbody>
            </table>
          </div>
        </div>
      </div>
    <% end %>
  </div>
<% end %>
```

4. The dropdown widgets (for Species / Home World / Affiliation) aren't hand-rolled — they're pulled in from the `tailwindcss-stimulus-components` npm package and registered like any other Stimulus controller.

**`app/javascript/controllers/index.js`** (registration, added lines)
```js
import { Dropdown } from "tailwindcss-stimulus-components"
application.register('dropdown', Dropdown)
```

5. The characters index is mounted as a lazy-loaded frame on the demo page, and a single read-only route is added.

**`config/routes.rb`** (addition)
```ruby
resources :characters, only: [:index]
```

**Why it matters / when to use:** Use this pattern any time you have a filterable index/table — the `autosubmit` + scoped `turbo_frame` combo gives you instant, server-rendered filtering with zero custom fetch/JSON code, and all the actual filter logic stays as ordinary, testable ActiveRecord scopes.

`Pattern:` search-filter, autosubmit, turbo-frames, stimulus, third-party-js, forms

---

## Day 8 — Ridiculously simple real-time chat

**Source:** https://x.com/itsameandrea/status/1629858696934338562  ·  **Date:** 2023-02-26  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/0934c93ca11ffdbae569a0daab9f6204e16fb668

A working multi-user chat room ships in about fifteen minutes using nothing but Action Cable's Turbo Stream integration. `Message#after_create_commit` broadcasts the newly created message straight into the chatroom's stream; every browser subscribed to that stream (via `turbo_stream_from`) gets the new `<div>` appended live with no controller code, channel definitions, or client-side WebSocket handling required. A tiny Stimulus controller resets the empty rich-text input after each send, and messages from the current user are right-aligned with plain CSS keyed off the user's id.

### How it works

1. `Chatroom` has many `Message`s. `Message` uses `has_rich_text :content` (Action Text/Trix) for the message body, and its `after_create_commit` callback is the entire real-time mechanism: it broadcasts an append of the rendered `messages/message` partial into the `chatroom_<id>` stream.

**`app/models/chatroom.rb`**
```ruby
class Chatroom < ApplicationRecord
  has_many :messages, dependent: :destroy
end
```

**`app/models/message.rb`**
```ruby
class Message < ApplicationRecord
  belongs_to :chatroom
  belongs_to :user

  has_rich_text :content

  after_create_commit {
    broadcast_append_to "chatroom_#{chatroom.id}",
      target: "messages",
      partial: 'messages/message'
  }
end
```

**`app/models/user.rb`** (addition)
```ruby
has_many :messages, dependent: :destroy
```

2. `ChatroomsController` requires authentication only to view a room, and eager-loads messages to avoid N+1 queries when rendering the show page. It also builds a blank `Message` for the form.

**`app/controllers/chatrooms_controller.rb`**
```ruby
class ChatroomsController < ApplicationController
  before_action :authenticate_user!, only: [:show]
  
  def index
    @chatrooms = Chatroom.all
  end

  def show
    @chatroom = Chatroom.includes(:messages).find(params[:id])
    @message = Message.new
  end
end
```

3. `MessagesController#create` is the only action needed to post a message — it just saves the record, stamps it with the current chatroom and user, and lets `after_create_commit` do the broadcasting. There's no `respond_to`/render at all; the response to the poster is irrelevant, the broadcast is what updates every screen.

**`app/controllers/messages_controller.rb`**
```ruby
class MessagesController < ApplicationController
  def create
    @chatroom = Chatroom.find(params[:chatroom_id])
    @message = Message.new(message_params)
    @message.chatroom = @chatroom
    @message.user = current_user

    @message.save!
  end

  private

  def message_params
    params.require(:message).permit(:content)
  end
end
```

4. The chatroom show page opens a live stream with `turbo_stream_from dom_id(@chatroom)` (matching the `chatroom_<id>` name used in the broadcast), renders existing messages into a `#messages` container that new ones get appended to, and posts new messages through a form pointed at the nested `messages` route. A scoped `<style>` block right-aligns and recolors the bubble for messages belonging to the current user, driven off a `msg-for-<user_id>` class on each message row.

**`app/views/chatrooms/show.html.erb`**
```erb
<style>
  <%= ".msg-for-#{current_user&.id}" %> {
    display: flex;
    justify-content: flex-end
  }
    
  <%= ".msg-for-#{current_user&.id}" %> .chat-img {
    order: 2;
    margin-left: 10px;
  }

  <%= ".msg-for-#{current_user&.id}" %> .chat-bubble {
    background-color: #5046E5 !important;
    color: #fff !important;
    padding: 10px;
  }
</style>

<%= turbo_stream_from dom_id(@chatroom) %>

<div class="flex flex-col flex-grow w-full bg-white shadow-xl rounded-lg overflow-hidden mx-auto h-screen">
  <div id="messages" class="flex flex-col flex-grow h-0 p-4 overflow-auto bg-gray-100">
    <% @chatroom.messages.each do |message| %>
      <%= render "messages/message", message: message %>
    <% end %>
  </div>
  
  <div class="p-4">
    <%= form_with model: @message,
      url: chatroom_messages_path(@chatroom),
      data: {controller: "form-reset", action: "turbo:submit-end->form-reset#reset"} do |f| %>
      <%= f.rich_text_area :content %>
      <%= f.submit "Send", class: "bg-indigo-600 px-3 py-1 rounded-md text-white float-right mt-10" %>
    <% end %>
  </div>
</div>
```

5. Each message row carries the `msg-for-<user_id>` class the scoped stylesheet above targets, so the exact same partial renders differently depending on who's viewing it.

**`app/views/messages/_message.html.erb`**
```erb
<div class="flex mt-2 space-x-3 w-full msg-for-<%= message.user.id %>">
  <div class="chat-img flex-shrink-0 h-10 w-10 rounded-full bg-gray-300">
  </div>
  <div class="max-w-xs">
    <div class="bg-gray-300 p-3 rounded-lg chat-bubble">
      <strong class="text-sm"><%= message.user.username %></strong>
      <p class="text-sm"><%= message.content %></p>
    </div>
    <span class="text-xs text-gray-500 leading-none"><%= time_ago_in_words(message.created_at) %></span>
  </div>
</div>
```

6. Since the message form isn't a full-page navigation, the Trix editor's content doesn't clear itself after a successful submit. The `form-reset` Stimulus controller wraps `this.element.reset()`, and the form wires it up to fire on Turbo's `turbo:submit-end` event (which fires whether the request is a Turbo Stream or a regular response).

**`app/javascript/controllers/form_reset_controller.js`**
```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="form-reset"
export default class extends Controller {
  reset() {
    this.element.reset()
  }
}
```

**`app/javascript/controllers/index.js`** (registration, added lines)
```js
import FormResetController from "./form_reset_controller"
application.register("form-reset", FormResetController)
```

7. `chatrooms/index.html.erb` lists all rooms behind a lazy-loaded turbo frame on the demo page, same pattern as previous days. Routes nest `messages` under `chatrooms`, and the Gemfile enables `image_processing` for Action Text attachments (Trix/Action Text was added as a dependency to support the rich-text message body).

**`config/routes.rb`** (additions)
```ruby
resources :chatrooms, only: [:index, :show] do 
  resources :messages, only: [:create]
end
```

**Why it matters / when to use:** This is the minimal template for any "broadcast a new record to everyone watching" feature — comments, notifications, live activity feeds — since the entire real-time layer is one `broadcast_append_to` call plus one `turbo_stream_from` tag; Action Cable's plumbing is completely hidden by Turbo Streams.

`Pattern:` broadcasts, actioncable, turbo-streams, stimulus, forms

---

## Day 9 — Real-time tic tac toe

**Source:** https://x.com/itsameandrea/status/1630233296511840256  ·  **Date:** 2023-02-27  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/pull/9

A two-player, real-time tic tac toe game built entirely server-side. Each cell is a `button_to` that creates a `TicTacToeMove`; after a move is saved, the model works out whether it was a winning move, a draw, or just a normal move, and broadcasts the right Turbo Stream update to both players' boards over the shared game's Action Cable stream. Player identity/turn tracking is handled with Kredis (a higher-level Redis client) rather than a database column, since it's ephemeral, per-session state rather than something that needs relational modeling.

### How it works

1. `TicTacToeGame` tracks its two players using `kredis_unique_list :player_ids, limit: 2` instead of a join table — a Redis-backed list that naturally dedupes and caps at 2. Helper methods derive the current player list, turn order, and win/draw status from that plus the game's moves.

**`app/models/tic_tac_toe_game.rb`**
```ruby
class TicTacToeGame < ApplicationRecord
  belongs_to :winner, class_name: 'User', optional: true
  has_many :tic_tac_toe_moves, dependent: :destroy
  
  kredis_unique_list :player_ids, limit: 2

  def players
    User.where(id: player_ids.elements)
  end

  def has_move?(position:)
    tic_tac_toe_moves.exists?(position: position)
  end

  def move_at(position:)
    tic_tac_toe_moves.find_by(position: position)
  end

  def add_player(user)
    player_ids << user.id
  end

  def player?(user)
    player_ids.elements.include?(user.id)
  end

  def first_player?(player)
    players.first == player
  end

  def full?
    player_ids.elements.size == 2
  end

  def over?
    winner.present? || tic_tac_toe_moves.count == 9
  end

  def symbol_for(player)
    player == players.first ? 'x' : '0'
  end
end
```

The `kredis` gem was uncommented in the Gemfile to enable this.

2. `TicTacToeMove.make` wraps creation and incrementing the move counter in a transaction. After every create, `broadcast_move` checks the 8 winning combinations; if the move wins, it updates the game's `winner` and broadcasts a "winner" partial; if it's the 9th move with no winner, it broadcasts a "draw" partial; otherwise it just replaces that one board cell with the player's symbol. All three cases broadcast to the same `tic_tac_toe_game_<id>` stream, targeting the outer `<section>` for win/draw and the specific `position_<n>` cell for a normal move.

**`app/models/tic_tac_toe_move.rb`**
```ruby
class TicTacToeMove < ApplicationRecord
  belongs_to :tic_tac_toe_game
  belongs_to :user

  validates :position, presence: true, inclusion: { in: 0..8 }
  validates :move_number, presence: true, inclusion: { in: 0..8 }, uniqueness: { scope: :tic_tac_toe_game_id }

  after_create_commit :broadcast_move

  WINNING_COMBINATIONS = [ 
    [0,1,2],
    [3,4,5],
    [6,7,8],
    [0,3,6],
    [1,4,7],
    [2,5,8],
    [0,4,8], 
    [6,4,2]
  ]

  def broadcast_move
    broadcast_id = "tic_tac_toe_game_#{tic_tac_toe_game.id}"

    if winning?
      tic_tac_toe_game.update!(winner: user)

      broadcast_update_to broadcast_id,
        target: broadcast_id,
        partial: "tic_tac_toe_games/winner",
        locals: { user: user }
    elsif last?
      broadcast_update_to broadcast_id,
        target: broadcast_id,
        partial: "tic_tac_toe_games/draw"
    else
      broadcast_replace_to broadcast_id,
        target: "position_#{position}",
        partial: "tic_tac_toe_moves/symbol_#{tic_tac_toe_game.symbol_for(user)}"
    end
  end

  def self.make(params)
    transaction do
      move = create!(params)
      move.increment!(:move_number)
    end
  end

  def winning?
    WINNING_COMBINATIONS.any? do |combination|
      combination.all? do |position|
        tic_tac_toe_game.move_at(position: position).try(:user) == user
      end
    end
  end

  def last?
    move_number == 8
  end
end
```

**`app/models/user.rb`** (additions)
```ruby
has_many :tic_tac_toe_games, dependent: :destroy
has_many :tic_tac_toe_moves, dependent: :destroy
```

3. `TicTacToeGamesController#create` creates a game and immediately adds the creator as its first player, then redirects to the game. `#show` auto-joins any other visiting user as the second player (unless they're already in it).

**`app/controllers/tic_tac_toe_games_controller.rb`**
```ruby
class TicTacToeGamesController < ApplicationController
  before_action :authenticate_user!, except: [:index]

  def index
    @games = TicTacToeGame.all
  end

  def show
    @game = TicTacToeGame.find(params[:id])
    @game.add_player(current_user) unless @game.player?(current_user)
  end

  def create
    @game = TicTacToeGame.create
    @game.add_player(current_user)

    redirect_to @game
  end
end
```

**`app/controllers/tic_tac_toe_moves_controller.rb`**
```ruby
class TicTacToeMovesController < ApplicationController
  def create
    @game = TicTacToeGame.find(params[:tic_tac_toe_game_id])
    TicTacToeMove.make(move_params.merge(tic_tac_toe_game: @game, user: current_user))
  end

  private

  def move_params
    params.require(:tic_tac_toe_move).permit(:position)
  end
end
```

4. A small helper works out which emoji symbol (❌/⭕) to show for a given player in the game header, based on their index in the players list.

**`app/helpers/tic_tac_toe_games_helper.rb`**
```ruby
module TicTacToeGamesHelper
  def symbol_for(player:, game:)
    player_index = game.players.index(player)
    player_index == 0 ? '❌' : '⭕'
  end
end
```

5. The games index lists all games, with a "New Game" button and a "Join" link for any game that isn't over yet.

**`app/views/tic_tac_toe_games/index.html.erb`**
```erb
<%= turbo_frame_tag "games", class: "w-full" do %>
  <div class="px-4 sm:px-6 lg:px-8">
    <div class="sm:flex sm:items-center">
      <div class="sm:flex-auto">
        <h1 class="text-base font-semibold leading-6 text-gray-900">Games 🏆</h1>
        <p class="mt-2 text-sm text-gray-700">A list of all the games.</p>
      </div>
      <div>
        <%= button_to "New Game", tic_tac_toe_games_path, method: :post, class: "inline-flex items-center px-4 py-2 border border-transparent text-sm font-medium rounded-md shadow-sm text-white bg-indigo-600 hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500" %>
      </div>
    </div>
    <div class="mt-8 flow-root">
      <div class="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
          <table class="min-w-full divide-y divide-gray-300">
            <thead>
              <tr>
                <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Name</th>
                <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Players</th>
                <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Actions</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <% @games.each do |game| %>
                <tr>
                  <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">Game #<%= game.id %></td>
                  <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0"><%= pluralize(game.player_ids.elements.count, 'player') %></td>
                  <td class="relative whitespace-nowrap py-4 pl-3 pr-4 text-right text-sm font-medium sm:pr-0">
                    <% unless game.over? %>
                      <%= link_to "Join", tic_tac_toe_game_path(game), class: "text-indigo-600 hover:text-indigo-900" %>
                    <% end %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
<% end %>
```

6. The game board opens a `turbo_stream_from dom_id(@game)` and renders 9 cells. Each empty cell is a `button_to` (a mini one-button form) that posts a `TicTacToeMove` for that position, using a predictable `position_<n>` DOM id so the broadcast in step 2 can target it directly. Cells that already have a move render the corresponding symbol partial instead.

**`app/views/tic_tac_toe_games/show.html.erb`**
```erb
<%= turbo_stream_from dom_id(@game) %>

<section class="flex flex-col h-screen duration-700 p-6 bg-green-500 items-center" id="<%= dom_id(@game) %>">
  <div class="flex max-w-xs mt-10">
    <h1 class="text-3xl text-white">
      <%= current_user.username %>
      <%= symbol_for(player: current_user, game: @game) %>
    </h1>
  </div>

  <div class="flex flex-col h-full justify-center content-center max-w-xs">
    <div class="self-center">
      <div class="grid grid-cols-3 gap-2">
        <% (0..8).each do |position| %>
          <div class="flex -mb-2">
            <% if @game.has_move?(position: position) %>
              <%= render "tic_tac_toe_moves/symbol_#{@game.symbol_for(@game.move_at(position: position).user)}" %>
            <% else %>
              <%= button_to "", tic_tac_toe_game_moves_path(@game, tic_tac_toe_move: { position: position }),
                form: {id: "position_#{position}"},
                class: "flex items-center justify-center w-20 mb-4 h-20 bg-transparent cursor-pointer border-white border-2 rounded-xl bg-white bg-opacity-0 hover:bg-opacity-25 duration-300" %>
            <% end %>
          </div>
        <% end %>
      </div>
    </div>
  </div>
</section>
```

7. Winner, draw, and per-symbol cell states are each their own tiny partial, swapped in by the model's broadcasts.

**`app/views/tic_tac_toe_games/_winner.html.erb`**
```erb
<h1> <%= user.username %> won! </h1>

<%= link_to "Back to all games", tic_tac_toe_games_path, class: "underline" %>
```

**`app/views/tic_tac_toe_games/_draw.html.erb`**
```erb
<h1> It's a draw! </h1>

<%= link_to "Back to all games", tic_tac_toe_games_path, class: "underline" %>
```

**`app/views/tic_tac_toe_moves/_symbol_x.html.erb`**
```erb
<div class="flex items-center justify-center w-20 mb-4 h-20 bg-transparent cursor-pointer border-white border-2 rounded-xl bg-white bg-opacity-0 hover:bg-opacity-25 duration-300">
  <span> ❌ </span>
</div>
```

**`app/views/tic_tac_toe_moves/_symbol_0.html.erb`**
```erb
<div class="flex items-center justify-center w-20 mb-4 h-20 bg-transparent cursor-pointer border-white border-2 rounded-xl bg-white bg-opacity-0 hover:bg-opacity-25 duration-300">
  <span> ⭕ </span>
</div>
```

8. Routes nest `tic_tac_toe_moves` (aliased as `moves`) under `tic_tac_toe_games`, and the games index is mounted as another lazy frame on the kitchen-sink demo page.

**`config/routes.rb`** (additions)
```ruby
resources :tic_tac_toe_games, only: [:index, :show, :create] do
  resources :tic_tac_toe_moves, only: [:create], as: :moves
end
```

**Why it matters / when to use:** Shows that "real-time multiplayer" doesn't require any client-side game-state logic at all — every rule (turns, win detection, draw detection) lives in the model, and Turbo Streams simply pushes the resulting HTML fragment to whichever cell or region changed, on both players' screens simultaneously.

`Pattern:` broadcasts, actioncable, turbo-streams, turbo-frames, lazy-frames

---

## Day 10 — Multi-step forms

**Source:** https://x.com/itsameandrea/status/1630603351636480000  ·  **Date:** 2023-02-28  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/1bd7c504a15ad6810f1090e6b2b9b91d17441020

A three-step developer-onboarding wizard (personal info → skills → preferences) is built without ever saving a partial record to the database. Each step is backed by a plain Ruby class that includes `ActiveModel::Model` rather than inheriting from `ActiveRecord::Base`, so it gets full form-builder and validation support while being entirely disconnected from a table. Validated data from each step is stashed in the session; only on the final step is a real `Developer` record created from the accumulated session data, after which the session is cleared. Each step's view is wrapped in the same `onboarding_form` turbo frame, so moving between steps feels like a SPA without any custom JS.

### How it works

1. Each step gets its own `ActiveModel::Model`-backed class, letting `form_with`, `f.label`, error rendering, etc. all work exactly as they would for an ActiveRecord model, and letting each step validate only the fields it owns.

**`app/models/onboarding/developer_information.rb`**
```ruby
module Onboarding
  class DeveloperInformation
    include ActiveModel::Model
    attr_accessor :first_name, :last_name, :location, :email

    validates :first_name, :last_name, :email, :location, presence: true
  end
end
```

**`app/models/onboarding/developer_skill.rb`**
```ruby
module Onboarding
  class DeveloperSkill
    include ActiveModel::Model
    attr_accessor :skills

    validates :skills, presence: true
  end
end
```

**`app/models/onboarding/developer_preference.rb`**
```ruby
module Onboarding
  class DeveloperPreference
    include ActiveModel::Model
    attr_accessor :day_rate, :preferred_contract_duration
    
    PREFERRED_CONTRACT_DURATION = ["1 month", "3 months", "6 months", "1 year"].freeze

    validates :day_rate, :preferred_contract_duration, presence: true
    validates :day_rate, numericality: { greater_than: 0 }
    validates :preferred_contract_duration, inclusion: { in: PREFERRED_CONTRACT_DURATION }
  end
end
```

2. The real, persisted `Developer` model (backed by ActiveRecord) is only used to store the final combined result once the wizard is complete.

**`app/models/developer.rb`**
```ruby
class Developer < ApplicationRecord
  def full_name
    "#{first_name} #{last_name}"
  end
end
```

3. Step 1's controller lives under an `Onboarding` namespace. `create` validates the submitted `DeveloperInformation` (via `.valid?`, no `save` — there's nothing to save to) and, if valid, writes its attributes into `session[:developer_information]` before redirecting to step 2. If invalid, it just re-renders `:new` with the model's errors already populated.

**`app/controllers/onboarding/developer_informations_controller.rb`**
```ruby
module Onboarding
  class DeveloperInformationsController < ApplicationController
    def new
      @developer_information = DeveloperInformation.new
    end

    def create
      @developer_information = DeveloperInformation.new(developer_information_params)

      if @developer_information.valid?
        session[:developer_information] = {
          first_name: @developer_information.first_name,
          last_name: @developer_information.last_name,
          location: @developer_information.location,
          email: @developer_information.email
        }

        redirect_to new_onboarding_developer_skill_path
      else
        render :new
      end
    end

    private

    def developer_information_params
      params.require(:onboarding_developer_information).permit(
        :first_name,
        :last_name,
        :email,
        :location
      )
    end
  end
end
```

Step 1's view renders a progress nav (highlighting the current step) inside the shared `onboarding_form` turbo frame, then a normal `form_with model:` form for the ActiveModel object:

**`app/views/onboarding/developer_informations/new.html.erb`**
```erb
<%= turbo_frame_tag "onboarding_form" do %>
  <nav aria-label="Progress">
    <ol role="list" class="space-y-4 md:flex md:space-y-0 md:space-x-8">
      <li class="md:flex-1">
        <!-- Completed Step -->
        <a href="#" class="group flex flex-col border-l-4 border-indigo-600 py-2 pl-4 hover:border-indigo-800 md:border-l-0 md:border-t-4 md:pl-0 md:pt-4 md:pb-0">
          <span class="text-sm font-medium text-indigo-600 group-hover:text-indigo-800">Step 1</span>
          <span class="text-sm font-medium">Personal Information</span>
        </a>
      </li>

      <li class="md:flex-1">
        <!-- Upcoming Step -->
        <a href="#" class="group flex flex-col border-l-4 border-gray-200 py-2 pl-4 hover:border-gray-300 md:border-l-0 md:border-t-4 md:pl-0 md:pt-4 md:pb-0">
          <span class="text-sm font-medium text-gray-500 group-hover:text-gray-700">Step 2</span>
          <span class="text-sm font-medium">Skills</span>
        </a>
      </li>

      <li class="md:flex-1">
        <!-- Upcoming Step -->
        <a href="#" class="group flex flex-col border-l-4 border-gray-200 py-2 pl-4 hover:border-gray-300 md:border-l-0 md:border-t-4 md:pl-0 md:pt-4 md:pb-0">
          <span class="text-sm font-medium text-gray-500 group-hover:text-gray-700">Step 3</span>
          <span class="text-sm font-medium">Preferences</span>
        </a>
      </li>
    </ol>
  </nav>

  <div class="bg-gray-100 py-8 px-4 shadow sm:rounded-lg sm:px-10 mt-10">
    <%= form_with model: @developer_information, class: "space-y-6" do |f| %>
      <div>
        <%= f.label :email, class: "block text-sm font-medium text-gray-700" %>
        <div class="mt-1">
          <%= f.email_field :email, class: "block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm" %>
        </div>
      </div>

      <div>
        <%= f.label :first_name, class: "block text-sm font-medium text-gray-700" %>
        <div class="mt-1">
          <%= f.text_field :first_name, class: "block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm" %>
        </div>
      </div>

      <div>
        <%= f.label :last_name, class: "block text-sm font-medium text-gray-700" %>
        <div class="mt-1">
          <%= f.text_field :last_name, class: "block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm" %>
        </div>
      </div>

      <div>
        <%= f.label :location, class: "block text-sm font-medium text-gray-700" %>
        <div class="mt-1">
          <%= f.text_field :location, class: "block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm" %>
        </div>
      </div>

      <div class="flex justify-end">
        <button type="submit" class="flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2">
          Next
        </button>
      </div>

      <% if @developer_information.errors.any? %>
        <p class="mt-2 text-sm text-red-600">
          <%= @developer_information.errors.full_messages.join(", ") %>
        </p>
      <% end %>
    <% end %>
  </div>
<% end %>
```

4. Step 2 follows the identical shape: validate the `DeveloperSkill`, stash it in `session[:developer_skills]`, redirect to step 3.

**`app/controllers/onboarding/developer_skills_controller.rb`**
```ruby
module Onboarding
  class DeveloperSkillsController < ApplicationController
    def new
      @developer_skills = DeveloperSkill.new
    end

    def create
      @developer_skills = DeveloperSkill.new(developer_skills_params)

      if @developer_skills.valid?
        session[:developer_skills] = {
          skills: @developer_skills.skills
        }

        redirect_to new_onboarding_developer_preference_path
      else
        render :new
      end
    end

    private

    def developer_skills_params
      params.require(:onboarding_developer_skill).permit(
        :skills
      )
    end
  end
end
```

Its view is the same progress-nav + form shape, just for the `skills` field (omitted here for brevity — structurally identical to step 1's view above, with "Step 2" highlighted as current).

5. Step 3 is where the wizard actually persists data: it validates the `DeveloperPreference`, merges its own params with both prior steps' session data, creates the real `Developer` record from the combined hash, then deletes both session keys so a stale wizard can't be resumed.

**`app/controllers/onboarding/developer_preferences_controller.rb`**
```ruby
module Onboarding
  class DeveloperPreferencesController < ApplicationController
    def new
      @developer_preferences = DeveloperPreference.new
    end

    def create
      @developer_preferences = DeveloperPreference.new(developer_preferences_params)

      if @developer_preferences.valid?
        all_params = developer_preferences_params.merge(session[:developer_information])
          .merge(session[:developer_skills])
        
        developer = Developer.create!(all_params)

        session.delete('developer_information')
        session.delete('developer_skills')

        redirect_to developer_path(developer), notice: 'Developer was successfully created.'
      else
        render :new
      end
    end

    private

    def developer_preferences_params
      params.require(:onboarding_developer_preference).permit(
        :day_rate,
        :preferred_contract_duration
      )
    end
  end
end
```

Its view adds a `select` populated from the model's own `PREFERRED_CONTRACT_DURATION` constant, keeping the allowed values defined in one place:

**`app/views/onboarding/developer_preferences/new.html.erb`** (form portion)
```erb
<%= form_with model: @developer_preferences, class: "space-y-6" do |f| %>
  <div>
    <%= f.label :day_rate, class: "block text-sm font-medium text-gray-700" %>
    <div class="mt-1">
      <%= f.text_field :day_rate, class: "block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm" %>
    </div>
  </div>

  <div>
    <%= f.label :preferred_contract_duration, class: "block text-sm font-medium text-gray-700" %>
    <div class="mt-1">
      <%= f.select :preferred_contract_duration, Onboarding::DeveloperPreference::PREFERRED_CONTRACT_DURATION, {}, class: "block w-full appearance-none rounded-md border border-gray-300 px-3 py-2 placeholder-gray-400 shadow-sm focus:border-indigo-500 focus:outline-none focus:ring-indigo-500 sm:text-sm" %>
    </div>
  </div>

  <div class="flex justify-end">
    <button type="submit" class="flex justify-center rounded-md border border-transparent bg-indigo-600 py-2 px-4 text-sm font-medium text-white shadow-sm hover:bg-indigo-700 focus:outline-none focus:ring-2 focus:ring-indigo-500 focus:ring-offset-2">
      Sign Up
    </button>
  </div>

  <% if @developer_preferences.errors.any? %>
    <p class="mt-2 text-sm text-red-600">
      <%= @developer_preferences.errors.full_messages.join(", ") %>
    </p>
  <% end %>
<% end %>
```

6. Once the `Developer` is created, `DevelopersController#show` renders the finished record — also wrapped in the same `onboarding_form` turbo frame, so the "Sign Up" submission on step 3 visually resolves into a summary card in the same spot the form used to be.

**`app/controllers/developers_controller.rb`**
```ruby
class DevelopersController < ApplicationController
  def show
    @developer = Developer.find(params[:id])
  end
end
```

**`app/views/developers/show.html.erb`**
```erb
<%= turbo_frame_tag "onboarding_form" do %>
  <div class="overflow-hidden bg-white shadow sm:rounded-lg">
    <div class="px-4 py-5 sm:px-6">
      <h3 class="text-base font-semibold leading-6 text-gray-900">Developer Information</h3>
      <p class="mt-1 max-w-2xl text-sm text-gray-500">Personal details and application.</p>
    </div>
    <div class="border-t border-gray-200 px-4 py-5 sm:p-0">
      <dl class="sm:divide-y sm:divide-gray-200">
        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5 sm:px-6">
          <dt class="text-sm font-medium text-gray-500">Full name</dt>
          <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"><%= @developer.full_name %></dd>
        </div>
        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5 sm:px-6">
          <dt class="text-sm font-medium text-gray-500">Email</dt>
          <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"><%= @developer.email %></dd>
        </div>
        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5 sm:px-6">
          <dt class="text-sm font-medium text-gray-500">Location</dt>
          <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"><%= @developer.location %></dd>
        </div>
        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5 sm:px-6">
          <dt class="text-sm font-medium text-gray-500">Day rate</dt>
          <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0">$<%= @developer.day_rate %></dd>
        </div>
        <div class="py-4 sm:grid sm:grid-cols-3 sm:gap-4 sm:py-5 sm:px-6">
          <dt class="text-sm font-medium text-gray-500">Contract preference</dt>
          <dd class="mt-1 text-sm text-gray-900 sm:col-span-2 sm:mt-0"><%= @developer.preferred_contract_duration %></dd>
        </div>
      </dl>
    </div>
  </div>
<% end %>
```

7. Routes namespace the three step resources under `onboarding`, each with only `:new`/`:create`, plus a top-level read-only `developers` resource for the final summary. The wizard's entry point is mounted as a lazy-loaded `onboarding_form` frame on the demo page.

**`config/routes.rb`** (additions)
```ruby
namespace :onboarding do
  resources :developer_informations, only: %i[new create]
  resources :developer_skills, only: %i[new create]
  resources :developer_preferences, only: %i[new create]
end

resources :developers, only: %i[show]
```

**Credit / further reading:** Andrea credits [Jason Swett's "Rails multi-step forms"](https://www.codewithjason.com/rails-multi-step-forms/) for the underlying approach. Jason's version namespaces the step objects (`Intake::UserProfile`, `Intake::UserAccount`), each a PORO including `ActiveModel::Model` so it plugs straight into `form_with` and `valid?`; each step's validated attributes are written to `session[:user_profile]` and the final controller merges them (`user_account_params.merge(first_name: session['user_profile']['first_name'], ...)`) into a single `User.create!`, then calls `session.delete('user_profile')`. Andrea's contribution is layering Turbo Frames on top so the wizard never does a full page load.

**Why it matters / when to use:** Use this whenever you need multi-step data collection with per-step validation but don't want an incomplete/partial record sitting in the database — `ActiveModel::Model` gives each step full form and validation ergonomics, the session acts as scratch storage between steps, and a shared turbo frame keeps the whole flow feeling like a single-page wizard.

`Pattern:` multi-step-forms, forms, validation, turbo-frames, lazy-frames

---

## Day 11 — Flash messages without a page reload

**Source:** https://x.com/itsameandrea/status/1630937460250406912  ·  **Date:** 2023-03-01  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/1e9139aef5b398ca31c240ccb7384845f591f114

Traditional Rails flashes only render on a full page load, which barely happens in a Hotwire app. The fix is a `turbo_frame_tag "flash"` in the layout used purely as a **named target**: the controller sets `flash.now[:notice]` (not `flash[]`, or the message reappears on the next navigation), responds with a Turbo Stream, and the stream does `turbo_stream.update "flash"` with the flash partial. A 15-line Stimulus controller auto-dismisses it after 2s and wires the close button.

### How it works

1. Put an empty flash frame in the layout as a stable target.

**`app/views/layouts/application.html.erb`**

```erb
<%= yield %>

<%= turbo_frame_tag "modal" %>
<%= turbo_frame_tag "flash" %>
```

2. In the controller, use `flash.now` and respond with a stream. Andrea calls this out explicitly: `flash.now` is required, otherwise the message will show again on the next real page navigation.

**`app/controllers/characters_controller.rb`**

```ruby
def destroy
  @character = Character.find(params[:id])

  respond_to do |format|
    if @character.destroy
      flash.now[:notice] = "Character was successfully deleted"
      format.turbo_stream
    end
  end
end
```

3. The stream removes the deleted row *and* fills the flash frame.

**`app/views/characters/destroy.turbo_stream.erb`**

```erb
<%= turbo_stream.remove dom_id(@character) %>
<%= turbo_stream.update "flash", partial: "shared/flash" %>
```

4. The partial iterates all flash keys and mounts the Stimulus controller on each toast.

**`app/views/shared/_flash.html.erb`**

```erb
<% flash.each do |key, value| %>
  <div
    class="max-w-sm w-full bg-white shadow-lg rounded-lg pointer-events-auto overflow-hidden fixed top-5 right-5"
    data-controller="flash">
    <div class="p-4">
      <div class="flex items-start">
        <div class="flex-shrink-0">
          <svg xmlns="http://www.w3.org/2000/svg" class="h-6 w-6 text-green-400" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>

        <div class="ml-3 w-0 flex-1 pt-0.5">
          <span class="text-sm text-gray-700 leading-5 font-medium">
            <%= value %>
          </span>
        </div>

        <div class="ml-4 flex-shrink-0 flex">
          <button
            class="bg-white rounded-md inline-flex text-gray-400 hover:text-gray-500 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500"
            data-action="flash#close">
            <span class="sr-only">Close</span>
            <!-- Heroicon name: solid/x -->
            <svg class="h-5 w-5" xmlns="http://www.w3.org/2000/svg" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M4.293 4.293a1 1 0 011.414 0L10 8.586l4.293-4.293a1 1 0 111.414 1.414L11.414 10l4.293 4.293a1 1 0 01-1.414 1.414L10 11.414l-4.293 4.293a1 1 0 01-1.414-1.414L8.586 10 4.293 5.707a1 1 0 010-1.414z" clip-rule="evenodd" />
            </svg>
          </button>
        </div>
      </div>
    </div>
  </div>
<% end %>
```

5. Auto-dismiss + manual close.

**`app/javascript/controllers/flash_controller.js`**

```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="flash"
export default class extends Controller {
  connect() {
    setTimeout(() => {
      this.close()
    }, 2000)
  }

  close() {
    this.element.remove()
  }
}
```

6. Each table row carries `dom_id` so it can be targeted, and the delete button is a plain `button_to`.

**`app/views/characters/index.html.erb`** (relevant fragment)

```erb
<tr id="<%= dom_id(character) %>">
  ...
  <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
    <%= button_to character_path(character), method: :delete do %>
      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
        <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
      </svg>
    <% end %>
  </td>
</tr>
```

**Why it matters / when to use:** Andrea says he uses this in every project. Any controller action that responds with a stream can now emit a toast by adding one line to its `.turbo_stream.erb`. The `flash.now` detail is the gotcha that bites everyone.

`Pattern:` turbo-streams, turbo-frames, flash, stimulus

---

## Day 12 — Command palette with a keyboard shortcut

**Source:** https://x.com/itsameandrea/status/1631313111784513536  ·  **Date:** 2023-03-02  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/8a19440d3c235667fcc6eccfece53bef5c2e7506

A ⌘K-style command palette, available app-wide, built from Stimulus' **built-in hotkey action syntax** (`keydown.ctrl+a->`, `keydown.esc->`) plus the Day 1 search-frame pattern. The controller is mounted on `<body>` so the shortcut works from anywhere; the palette partial is rendered once in the layout; the results list is a Turbo Frame fed by the reusable `autosubmit` controller.

### How it works

1. Mount the controller on the body and bind the hotkeys. Stimulus supports key filters natively — no hotkeys library needed.

**`app/views/layouts/application.html.erb`**

```erb
<body
  data-controller="command-palette"
  data-action="keydown.ctrl+a->command-palette#toggle keydown.esc->command-palette#close">
  <%= render 'shared/flash' %>

  <%= yield %>

  <%= render 'shared/command_palette' %>

  <%= turbo_frame_tag "modal" %>
  <%= turbo_frame_tag "flash" %>
</body>
```

2. The controller toggles a `hidden` class and moves focus into the input on open.

**`app/javascript/controllers/command_palette_controller.js`**

```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="command-palette"
export default class extends Controller {
  static targets = [ "palette", "input" ]

  isVisible() {
    return !this.paletteTarget.className.includes("hidden")
  }

  toggle() {
    this.paletteTarget.classList.toggle("hidden")

    if (this.isVisible()) {
      this.inputTarget.value = ""
      this.inputTarget.focus()
    }
  }

  close() {
    this.paletteTarget.classList.add("hidden")
  }
}
```

3. The palette itself is a TailwindUI dialog whose search form auto-submits into a `commands` Turbo Frame — exactly the Day 1 mechanism.

**`app/views/shared/_command_palette.html.erb`**

```erb
<div class="relative z-10 hidden" data-command-palette-target="palette" role="dialog" aria-modal="true">
  <div class="fixed inset-0 bg-gray-900 bg-opacity-40 transition-opacity"></div>

  <div class="fixed inset-0 z-10 overflow-y-auto p-4 sm:p-6 md:p-20">
    <div class="mx-auto max-w-xl transform divide-y divide-gray-100 overflow-hidden rounded-xl bg-white shadow-2xl ring-1 ring-black ring-opacity-5 transition-all">
      <%= form_tag commands_path, class: "relative", method: :get, data: {controller: "autosubmit", turbo_frame: "commands"} do %>
        <svg class="pointer-events-none absolute top-3.5 left-4 h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
          <path fill-rule="evenodd" d="M9 3.5a5.5 5.5 0 100 11 5.5 5.5 0 000-11zM2 9a7 7 0 1112.452 4.391l3.328 3.329a.75.75 0 11-1.06 1.06l-3.329-3.328A7 7 0 012 9z" clip-rule="evenodd" />
        </svg>
        <input
          name="query"
          data-command-palette-target="input"
          data-action="input->autosubmit#debouncedSubmit"
          type="text"
          class="h-12 w-full border-0 bg-transparent pl-11 pr-4 text-gray-900 placeholder:text-gray-400 focus:ring-0 sm:text-sm" placeholder="Search..." role="combobox" aria-expanded="false" aria-controls="options">
      <% end %>

      <%= turbo_frame_tag "commands", src: commands_path %>
    </div>
  </div>
</div>
```

4. Results are server-rendered inside the matching frame.

**`app/views/commands/index.html.erb`**

```erb
<%= turbo_frame_tag "commands" do %>
  <% if @commands.any? && params[:query].present? %>
    <ul class="max-h-72 scroll-py-2 overflow-y-auto py-2 text-sm text-gray-800" id="options" role="listbox">
      <% @commands.each do |command| %>
        <li class="cursor-default select-none px-4 py-2 active:bg-indigo-600 hover:bg-indigo-600 hover:text-white" id="option-1" role="option" tabindex="-1">
          <%= command.name %>
        </li>
      <% end %>
    </ul>
  <% elsif params[:query].present? %>
    <p class="p-4 text-sm text-gray-500">No commands found.</p>
  <% end %>
<% end %>
```

**`app/controllers/commands_controller.rb`**

```ruby
class CommandsController < ApplicationController
  def index
    @commands = Command.search(params)
  end
end
```

**`app/models/command.rb`**

```ruby
class Command < ApplicationRecord
  scope :by_name, -> (query) { where("name LIKE ?", "%#{query}%") }

  def self.search(params)
    commands = where(nil)
    commands = commands.by_name(params[:query])
    commands
  end
end
```

**`config/routes.rb`**

```ruby
resources :commands, only: %i[index]
```

**Why it matters / when to use:** Two Stimulus features carry the whole thing — key-filtered actions and targets. Because search results are a frame, ranking/filtering stays in Ruby and the palette scales to any dataset without shipping it to the client.

`Pattern:` stimulus, hotkeys, stimulus-targets, turbo-frames, autosubmit, search-filter, modals

---

## Day 13 — Quick and easy reactive maps (Mapbox)

**Source:** https://x.com/itsameandrea/status/1631690887289008129  ·  **Date:** 2023-03-03  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/d2f5be510fe9798ebe185dec4b5678473fc220e4

Wrapping a third-party JS widget in a Stimulus controller and putting the whole thing inside a Turbo Frame gets you a "reactive" map for free: submit an address, the frame reloads, the controller re-initialises with the new marker set, the form clears itself. Data crosses the boundary via **Stimulus values** (`data-mapbox-markers-value`, `data-mapbox-api-key-value`) rather than a JSON API. Geocoding is done server-side by the `geocoder` gem in an `after_validation` callback.

### How it works

1. Add the geocoder gem and geocode on save.

**`Gemfile`**

```ruby
gem "geocoder", "~> 1.8"
```

**`app/models/place.rb`**

```ruby
class Place < ApplicationRecord
  geocoded_by :address
  after_validation :geocode, if: :will_save_change_to_address?

  def as_marker
    { lat: latitude, lng: longitude }
  end
end
```

2. The Stimulus controller wraps `mapbox-gl`. Note the use of `static values` for typed props and private methods (`#addMarkers`) for internals.

**`app/javascript/controllers/mapbox_controller.js`**

```js
import { Controller } from "@hotwired/stimulus"
import mapboxgl from "mapbox-gl"

// Connects to data-controller="mapbox"
export default class extends Controller {
  static values = {
    apiKey: String,
    markers: Array
  }

  initialize() {
    mapboxgl.accessToken = this.apiKeyValue

    this.map = new mapboxgl.Map({
      container: this.element,
      style: "mapbox://styles/mapbox/streets-v10"
    })

    this.map.addControl(new mapboxgl.NavigationControl())

    this.#addMarkers()
    this.#centerMap()
  }

  #addMarkers() {
    this.markersValue.forEach((marker) => {
      new mapboxgl.Marker()
        .setLngLat([marker.lng, marker.lat])
        .addTo(this.map)
    })
  }

  #centerMap() {
    if (this.markersValue.length === 0) return

    const bounds = new mapboxgl.LngLatBounds()

    this.markersValue.forEach((marker) => {
      bounds.extend([marker.lng, marker.lat])
    })

    this.map.fitBounds(bounds, { padding: 70, maxZoom: 15, duration: 0 })
  }
}
```

3. Both the form and the map live inside the **same** `places` frame. That is what makes it reactive: creating a place redirects back to `places_path`, the frame swaps, the form is blank again and the controller re-initialises with the updated markers array.

**`app/views/places/index.html.erb`**

```erb
<%= turbo_frame_tag "places" do %>
  <%= form_with model: @place, url: places_path, class: "mb-10" do |f| %>
    <div>
      <%= f.label :address, class: "block text-sm font-medium leading-6 text-gray-900" %>
      <div class="mt-2">
        <%= f.text_field :address, class: "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6", placeholder: "e.g. Colosseum" %>
      </div>
    </div>
  <% end %>

  <div
    style="width: 100%; height: 500px;"
    data-controller="mapbox"
    data-mapbox-markers-value="<%= @places.map(&:as_marker).to_json %>"
    data-mapbox-api-key-value="<%= Rails.application.credentials.dig(:mapbox, :api_key) %>">
  </div>
<% end %>
```

**`app/controllers/places_controller.rb`**

```ruby
class PlacesController < ApplicationController
  def index
    @places = Place.all
    @place = Place.new
  end

  def create
    @place = Place.new(place_params)

    if @place.save
      redirect_to places_path
    else
      render :index
    end
  end

  private

  def place_params
    params.require(:place).permit(:name, :address)
  end
end
```

**`app/views/layouts/application.html.erb`**

```erb
<link href='https://api.mapbox.com/mapbox-gl-js/v2.13.0/mapbox-gl.css' rel='stylesheet' />
```

**`config/routes.rb`**

```ruby
resources :places, only: %i[index create]
```

**Why it matters / when to use:** The template for integrating *any* imperative JS library (charts, editors, maps) with Hotwire: values in, library instance owned by the controller, frame reload as the update mechanism. Andrea notes in replies that a finer-grained version would hook Turbo Frame events to add markers incrementally instead of re-initialising — see Day 27 for that technique.

`Pattern:` stimulus, stimulus-values, turbo-frames, third-party-js, forms

---

## Day 14 — Hotwire with ViewComponents

**Source:** https://x.com/itsameandrea/status/1632033471882469378  ·  **Date:** 2023-03-04  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/4eafc9935a999f348c430a050599e90bf0b41b46

A two-column todo list where ticking a checkbox moves the item between "to read" and "read". The Hotwire-specific lesson is in the stream template: `turbo_stream.append` normally takes `partial:`, and **ViewComponents can't be passed that way** — you render the component inside a block instead. The component also computes its own `div_id` that encodes which column it currently lives in, so the stream knows exactly what to remove.

### How it works

1. Model scopes for the two lists.

**`app/models/todo.rb`**

```ruby
class Todo < ApplicationRecord
  scope :completed, -> { where(completed: true) }
  scope :incomplete, -> { where(completed: false) }
end
```

2. A list component and an item component. The item's `div_id` prefixes `dom_id` with its current column — the key trick that makes the remove-then-append swap unambiguous.

**`app/components/todo_list_component.rb`**

```ruby
# frozen_string_literal: true

class TodoListComponent < ViewComponent::Base
  attr_reader :todos, :id, :title

  def initialize(id:, title:, todos: [])
    @todos = todos
    @id = id
    @title = title
  end
end
```

**`app/components/todo_list_component.html.erb`**

```erb
<div>
  <h1 class="text-xl font-bold mb-10"><%= title %></h1>

  <div id="<%= id %>" class="max-w-2xl">
    <%= render TodoComponent.with_collection(todos) %>
  </div>
</div>
```

**`app/components/todo_component.rb`**

```ruby
# frozen_string_literal: true

class TodoComponent < ViewComponent::Base
  attr_reader :todo

  def initialize(todo:)
    @todo = todo
  end

  def div_id
    "#{todo.completed? ? 'completed' : 'incomplete'}_#{dom_id(todo)}"
  end
end
```

**`app/components/todo_component.html.erb`**

```erb
<div
  id="<%= div_id %>"
  class="relative flex items-start animate__animated"
  data-entering-class="animate__fadeInUp"
  data-leaving-class="animate__fadeOutDown">
  <div class="flex h-6 items-center">
    <%= form_with model: todo, method: :patch, data: {controller: "autosubmit"}, class: "flex h-6 items-center" do |f| %>
      <%= f.check_box :completed, checked: todo.completed?, data: { action: "autosubmit#submit"}, class: "h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600" %>
    <% end %>
  </div>
  <div class="ml-3">
    <label for="comments" class="text-sm font-medium leading-6 text-gray-900"><%= todo.title %></label>
    <p id="comments-description" class="text-sm text-gray-500"><%= todo.description %></p>
  </div>
</div>
```

3. The page renders two lists inside a frame, and reuses the Day 3 `stream-animations` controller so items fade between columns.

**`app/views/todos/index.html.erb`**

```erb
<%= turbo_frame_tag "todos" do %>
  <div class="flex space-x-10 p-10" data-controller="stream-animations">
    <%= render TodoListComponent.new(
      title: "Books to read",
      id: "incomplete_todos",
      todos: @incomplete_todos
    ) %>

    <%= render TodoListComponent.new(
      title: "Books I read",
      id: "completed_todos",
      todos: @completed_todos
    ) %>
  </div>

<% end %>
```

4. **The ViewComponent + Turbo Stream idiom.** Because `turbo_stream.append "id", partial:` has no component equivalent, use the block form and `render Component.new(...)` inside it.

**`app/views/todos/update.turbo_stream.erb`**

```erb
<% if @todo.completed? %>
  <%= turbo_stream.remove "incomplete_#{dom_id(@todo)}" %>
  <%= turbo_stream.append "completed_todos" do %>
    <%= render TodoComponent.new(todo: @todo) %>
  <% end %>
<% else %>
  <%= turbo_stream.remove "completed_#{dom_id(@todo)}" %>
  <%= turbo_stream.append "incomplete_todos" do %>
    <%= render TodoComponent.new(todo: @todo) %>
  <% end %>
<% end %>
```

**`app/controllers/todos_controller.rb`**

```ruby
class TodosController < ApplicationController
  def index
    @completed_todos = Todo.completed
    @incomplete_todos = Todo.incomplete
  end

  def update
    @todo = Todo.find(params[:id])

    respond_to do |format|
      if @todo.update(todo_params)
        format.turbo_stream
      end
    end
  end

  private

  def todo_params
    params.require(:todo).permit(:completed)
  end
end
```

**`Gemfile`**

```ruby
gem "view_component"
```

**`config/routes.rb`**

```ruby
resources :todos, only: %i[index update]
```

**Why it matters / when to use:** If your app standardises on ViewComponent, this is the one incompatibility you will hit. Remember: block form for streams, and give components a deterministic `id` method so streams can target them.

`Pattern:` view-components, turbo-streams, turbo-frames, autosubmit, animation

---

## Day 15 — ChatGPT + Hotwire (long-running job, live result)

**Source:** https://x.com/itsameandrea/status/1632393551274446848  ·  **Date:** 2023-03-05  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/7dc418fbe79a01f85736882bdf1c88421fffcc78

A coffee-recipe generator backed by the OpenAI API. The pattern generalises to **any slow third-party call**: the `create` action doesn't redirect — it renders a `create.html.erb` that shows a spinner and opens an ActionCable stream scoped to the new record. An `after_create_commit` callback enqueues a background job, and when the job finishes it broadcasts a `replace` that swaps the spinner for the result. The user never waits on a blocking request.

### How it works

1. Enums drive the form and the prompt; `after_create_commit` kicks off the job.

**`app/models/coffee_prompt.rb`**

```ruby
class CoffeePrompt < ApplicationRecord
  after_create_commit :generate_recipe

  enum brew_method: {
    espresso: "espresso",
    v60: "v60",
    aeropress: "aeropress",
  }

  enum roast_level: {
    light: "light",
    medium: "medium",
    dark: "dark"
  }

  enum temperature: {
    hot: "hot",
    iced: "iced"
  }

  private

  def generate_recipe
    GenerateCoffeeRecipeJob.perform_later(self)
  end
end
```

2. The form loops over the enum values to build radio buttons, and is wrapped in a `coffee_prompt` frame nested inside an outer `coffeegpt` frame — so submitting replaces only the form area.

**`app/views/coffee_prompts/new.html.erb`**

```erb
<%= turbo_frame_tag "coffeegpt" do %>

  <%= turbo_frame_tag "coffee_prompt" do %>
    <%= form_with model: @coffee_prompt, class: "flex flex-col p-6" do |f| %>
      <h2 class="text-2xl mb-6 font-bold">
        How are you extracting your coffee?
      </h2>
      <ul class="grid w-full gap-6 md:grid-cols-3 mb-6">
        <% CoffeePrompt.brew_methods.each do |key, label| %>
          <li>
            <%= f.radio_button :brew_method, key.to_sym, class: "hidden peer", required: true %>
            <%= f.label :brew_method, value: key, class: "inline-flex items-center justify-between w-full p-5 text-gray-500 bg-white border border-gray-200 rounded-lg cursor-pointer dark:hover:text-gray-300 dark:border-gray-700 dark:peer-checked:text-blue-500 peer-checked:border-blue-600 peer-checked:text-blue-600 hover:text-gray-900 hover:bg-gray-100 dark:text-gray-900 dark:bg-gray-100 dark:hover:bg-gray-200" do %>
              <div class="block">
                <div class="w-full text-lg font-semibold"><%= label %></div>
              </div>
              <%= image_tag "#{label}.png", class:"w-6 h-6 ml-3" %>
            <% end %>
          </li>
        <% end %>
      </ul>

      <h2 class="text-2xl mb-6 font-bold">
        What roast level is your coffee?
      </h2>
      <ul class="grid w-full gap-6 md:grid-cols-3 mb-6">
        <% CoffeePrompt.roast_levels.each do |key, label| %>
          <li>
            <%= f.radio_button :roast_level, key.to_sym, class: "hidden peer", required: true %>
            <%= f.label :roast_level, value: key, class: "inline-flex items-center justify-between w-full p-5 text-gray-500 bg-white border border-gray-200 rounded-lg cursor-pointer dark:hover:text-gray-300 dark:border-gray-700 dark:peer-checked:text-blue-500 peer-checked:border-blue-600 peer-checked:text-blue-600 hover:text-gray-900 hover:bg-gray-100 dark:text-gray-900 dark:bg-gray-100 dark:hover:bg-gray-200" do %>
              <div class="block">
                <div class="w-full text-lg font-semibold"><%= label %></div>
              </div>
            <% end %>
          </li>
        <% end %>
      </ul>

      <h2 class="text-2xl mb-6 font-bold">
        Hot or iced?
      </h2>
      <ul class="grid w-full gap-6 md:grid-cols-3 mb-10">
        <% CoffeePrompt.temperatures.each do |key, label| %>
          <li>
            <%= f.radio_button :temperature, key.to_sym, class: "hidden peer", required: true %>
            <%= f.label :temperature, value: key, class: "inline-flex items-center justify-between w-full p-5 text-gray-500 bg-white border border-gray-200 rounded-lg cursor-pointer dark:hover:text-gray-300 dark:border-gray-700 dark:peer-checked:text-blue-500 peer-checked:border-blue-600 peer-checked:text-blue-600 hover:text-gray-900 hover:bg-gray-100 dark:text-gray-900 dark:bg-gray-100 dark:hover:bg-gray-200" do %>
              <div class="block">
                <div class="w-full text-lg font-semibold"><%= label %></div>
              </div>
              <%= image_tag "#{label}.png", class:"w-6 h-6 ml-3" %>
            <% end %>
          </li>
        <% end %>
      </ul>

      <%= f.submit "Generate my recipe", class: "bg-indigo-600 hover:bg-indigo-700 p-3 rounded-lg text-white cursor-pointer" %>
    <% end %>
  <% end %>

<% end %>
```

3. `create` renders a template instead of redirecting. **This is the crux** — the template is the loading state *and* the subscription.

**`app/controllers/coffee_prompts_controller.rb`**

```ruby
class CoffeePromptsController < ApplicationController
  def new
    @coffee_prompt = CoffeePrompt.new
  end

  def create
    @coffee_prompt = CoffeePrompt.new(coffee_prompt_params)

    unless @coffee_prompt.save
      render :new
    end
  end

  private

  def coffee_prompt_params
    params.require(:coffee_prompt).permit(:brew_method, :temperature, :roast_level)
  end
end
```

**`app/views/coffee_prompts/create.html.erb`**

```erb
<%= turbo_frame_tag "coffee_prompt" do  %>
  <%= turbo_stream_from dom_id(@coffee_prompt) %>

  <div id="loading" class="min-h-[500px] flex items-center justify-center">
    <div role="status">
      <svg aria-hidden="true" class="inline w-10 h-10 mr-2 text-gray-200 animate-spin dark:text-gray-600 fill-blue-600" viewBox="0 0 100 101" fill="none" xmlns="http://www.w3.org/2000/svg">
        <path d="M100 50.5908C100 78.2051 77.6142 100.591 50 100.591C22.3858 100.591 0 78.2051 0 50.5908C0 22.9766 22.3858 0.59082 50 0.59082C77.6142 0.59082 100 22.9766 100 50.5908ZM9.08144 50.5908C9.08144 73.1895 27.4013 91.5094 50 91.5094C72.5987 91.5094 90.9186 73.1895 90.9186 50.5908C90.9186 27.9921 72.5987 9.67226 50 9.67226C27.4013 9.67226 9.08144 27.9921 9.08144 50.5908Z" fill="currentColor"/>
        <path d="M93.9676 39.0409C96.393 38.4038 97.8624 35.9116 97.0079 33.5539C95.2932 28.8227 92.871 24.3692 89.8167 20.348C85.8452 15.1192 80.8826 10.7238 75.2124 7.41289C69.5422 4.10194 63.2754 1.94025 56.7698 1.05124C51.7666 0.367541 46.6976 0.446843 41.7345 1.27873C39.2613 1.69328 37.813 4.19778 38.4501 6.62326C39.0873 9.04874 41.5694 10.4717 44.0505 10.1071C47.8511 9.54855 51.7191 9.52689 55.5402 10.0491C60.8642 10.7766 65.9928 12.5457 70.6331 15.2552C75.2735 17.9648 79.3347 21.5619 82.5849 25.841C84.9175 28.9121 86.7997 32.2913 88.1811 35.8758C89.083 38.2158 91.5421 39.6781 93.9676 39.0409Z" fill="currentFill"/>
      </svg>
      <span class="sr-only">Loading...</span>
    </div>
  </div>
<% end %>
```

4. The job calls OpenAI and broadcasts a replace onto the `loading` div.

**`app/jobs/generate_coffee_recipe_job.rb`**

```ruby
class GenerateCoffeeRecipeJob < ApplicationJob
  queue_as :default

  def perform(coffee_prompt)
    client = OpenAiClient.new
    recipe = client.generate_recipe_for(coffee_prompt: coffee_prompt)

    Turbo::StreamsChannel.broadcast_replace_to "coffee_prompt_#{coffee_prompt.id}",
      target: "loading",
      partial: 'coffee_prompts/recipe', locals: { recipe: recipe }
  end
end
```

**`app/views/coffee_prompts/_recipe.html.erb`**

```erb
<div class="p-10">
  <p class="whitespace-pre">
    <%= recipe.try(:html_safe) %>
  </p>
</div>
```

5. A thin wrapper around the `ruby-openai` gem.

**`app/clients/open_ai_client.rb`**

```ruby
class OpenAiClient
  def initialize()
    @client = OpenAI::Client.new(access_token: Rails.application.credentials.dig(:open_ai, :api_key))
  end

  def generate_recipe_for(coffee_prompt:)
    response = @client.chat(
      parameters: {
          model: "gpt-3.5-turbo", # Required.
          messages: [{
            role: "user",
            content: "
              You are the world barista champion.
              I have a #{coffee_prompt.roast_level} coffee.
              I want to brew a #{coffee_prompt.brew_method}.
              I want to drink it #{coffee_prompt.temperature}.
              Give me a step-by-step tasty recipe"
          }],
          temperature: 0.7
      })

    response.dig("choices", 0, "message", "content")
  end
end
```

**`Gemfile`**

```ruby
gem "ruby-openai", "~> 3.5"
```

**`config/routes.rb`**

```ruby
resources :coffee_prompts, only: %i[new create]
```

**Why it matters / when to use:** The generic "slow work, live result" recipe — AI calls, PDF generation, imports, third-party syncs. Render a per-record stream subscription + spinner immediately, broadcast the replacement from the job. Note `broadcast_replace_to` is called directly on `Turbo::StreamsChannel` from the job rather than via a model callback.

`Pattern:` turbo-frames, turbo-streams, broadcasts, actioncable, forms, ai

---

## Day 16 — Tabbed content with Turbo Frames

**Source:** _thread not linked in container (see Gaps)_  ·  **Date:** 2023-03-06  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/cd3d8b9

Tabs with zero JavaScript. Each tab is a real route with its own view; all three views wrap themselves in the **same** `current_tab` frame and each one re-renders the shared tab bar. Clicking a tab link is an ordinary navigation that Turbo scopes to the frame, so only the tab content is swapped. Active-state highlighting is done server-side with a small `nav_link_to` helper built on `current_page?`.

### How it works

1. A helper that appends an `active_class` when the link points at the current page.

**`app/helpers/application_helper.rb`**

```ruby
module ApplicationHelper
  include Pagy::Frontend

  def nav_link_to(text, path, options = {})
    options[:class] = options[:class] || ""
    options[:class] += " #{options[:active_class]}" if current_page?(path)
    link_to text, path, options
  end
end
```

2. The tab bar is a shared partial. Because it's re-rendered with every tab response, the active state is always correct — no client state to sync.

**`app/views/shared/_tabs.html.erb`**

```erb
<div>
  <div class="hidden sm:block">
    <div class="border-b border-gray-200">
      <nav class="-mb-px flex space-x-8" aria-label="Tabs">
        <%= nav_link_to "Profile", profile_tab_path,
          active_class: "border-indigo-500 text-indigo-600",
          class: "whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium" %>
        <%= nav_link_to "Personal Information", personal_info_tab_path,
          active_class: "border-indigo-500 text-indigo-600",
          class: "whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium" %>
        <%= nav_link_to "Notifications", notifications_tab_path,
          active_class: "border-indigo-500 text-indigo-600",
          class: "whitespace-nowrap border-b-2 py-4 px-1 text-sm font-medium" %>
      </nav>
    </div>
  </div>
</div>
```

3. The container page is nothing but a frame that lazily loads the default tab.

**`app/views/pages/tabs.html.erb`**

```erb
<%= turbo_frame_tag "tabs" do %>

  <%= turbo_frame_tag "current_tab", src: profile_tab_path %>

<% end %>
```

**`app/views/pages/kitchensink.html.erb`** (host page)

```erb
<%= render "shared/divider", title: "Day 16/30 - Tabbed content" %>

<div class="mx-auto my-20 flex items-center justify-center">
  <%= turbo_frame_tag "tabs", src: tabs_path, class: "w-full" %>
</div>
```

4. **Every** tab view opens with the same two lines — the shared frame id and the tab bar — then its own content. Because the tab links live *inside* the `current_tab` frame, Turbo automatically scopes their navigation to that frame; no `data-turbo-frame` attribute is needed anywhere.

**`app/views/pages/profile_tab.html.erb`**

```erb
<%= turbo_frame_tag "current_tab" do %>
  <%= render 'shared/tabs' %>

  <div class="bg-white px-4 py-5 shadow sm:rounded-lg sm:p-6">
    <div class="md:grid md:grid-cols-3 md:gap-6">
      <div class="md:col-span-1">
        <h3 class="text-base font-semibold leading-6 text-gray-900">Profile</h3>
        <p class="mt-1 text-sm text-gray-500">This information will be displayed publicly so be careful what you share.</p>
      </div>
      <div class="mt-5 space-y-6 md:col-span-2 md:mt-0">
        <div class="grid grid-cols-3 gap-6">
          <div class="col-span-3 sm:col-span-2">
            <label for="company-website" class="block text-sm font-medium leading-6 text-gray-900">Website</label>
            <div class="mt-2 flex rounded-md shadow-sm">
              <span class="inline-flex items-center rounded-l-md border border-r-0 border-gray-300 px-3 text-gray-500 sm:text-sm">http://</span>
              <input type="text" name="company-website" id="company-website" class="block w-full flex-1 rounded-none rounded-r-md border-0 py-1.5 text-gray-900 ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6" placeholder="www.example.com">
            </div>
          </div>
        </div>

        <div>
          <label for="about" class="block text-sm font-medium leading-6 text-gray-900">About</label>
          <div class="mt-2">
            <textarea id="about" name="about" rows="3" class="block w-full rounded-md border-0 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:py-1.5 sm:text-sm sm:leading-6" placeholder="you@example.com"></textarea>
          </div>
          <p class="mt-2 text-sm text-gray-500">Brief description for your profile. URLs are hyperlinked.</p>
        </div>

        <!-- Photo / Cover photo fields omitted for brevity (static TailwindUI markup) -->
      </div>
    </div>
  </div>
<% end %>
```

**`app/views/pages/personal_info_tab.html.erb`** (same shape)

```erb
<%= turbo_frame_tag "current_tab" do %>
  <%= render 'shared/tabs' %>

  <div class="bg-white px-4 py-5 shadow sm:rounded-lg sm:p-6">
    <div class="md:grid md:grid-cols-3 md:gap-6">
      <div class="md:col-span-1">
        <h3 class="text-base font-semibold leading-6 text-gray-900">Personal Information</h3>
        <p class="mt-1 text-sm text-gray-500">Use a permanent address where you can receive mail.</p>
      </div>
      <div class="mt-5 md:col-span-2 md:mt-0">
        <!-- first name / last name / email / country / address fields -->
      </div>
    </div>
  </div>
<% end %>
```

**`app/views/pages/notifications_tab.html.erb`** (same shape)

```erb
<%= turbo_frame_tag "current_tab" do %>
  <%= render 'shared/tabs' %>

  <div class="bg-white px-4 py-5 shadow sm:rounded-lg sm:p-6">
    <div class="md:grid md:grid-cols-3 md:gap-6">
      <div class="md:col-span-1">
        <h3 class="text-base font-semibold leading-6 text-gray-900">Notifications</h3>
        <p class="mt-1 text-sm text-gray-500">Decide which communications you'd like to receive and how.</p>
      </div>
      <div class="mt-5 space-y-6 md:col-span-2 md:mt-0">
        <!-- By Email checkboxes + Push Notifications radios -->
      </div>
    </div>
  </div>
<% end %>
```

5. Plain controller actions and routes.

**`app/controllers/pages_controller.rb`**

```ruby
def tabs
end

def profile_tab
end

def personal_info_tab
end

def notifications_tab
end
```

**`config/routes.rb`**

```ruby
get 'tabs', to: 'pages#tabs'
get 'profile_tab', to: 'pages#profile_tab'
get 'personal_info_tab', to: 'pages#personal_info_tab'
get 'notifications_tab', to: 'pages#notifications_tab'
```

**Why it matters / when to use:** Settings screens, dashboards, profile pages — anywhere tabs would otherwise mean either rendering all panels up front or writing a JS tab component. Each panel is lazily fetched only when opened, and each is independently addressable/testable.

`Pattern:` turbo-frames, lazy-frames

---

## Day 17 — Twitter-style preview / undo / send

**Source:** https://x.com/itsameandrea/status/1633149666761007104  ·  **Date:** 2023-03-07  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/b9c0d9b805d4129941836e7129c2206076d4a372

Hit "Tweet" and instead of posting immediately you get a countdown with "Send now" and "Undo". This came from a challenge about whether Stimulus could match the React version — it takes ~30 lines. The submit handler calls `preventDefault()`, swaps in a `<template>` of preview actions, and starts a 5-second interval that calls `requestSubmit()` at zero. "Undo" is just a `link_to` back to `new_tweet_path` inside the frame; **`data-turbo-permanent` on the textarea** is what preserves the typed text across that frame reload.

### How it works

1. The controller. `static values` gives the countdown a default of 5 seconds; `showActions()` replaces the button row with the template's contents.

**`app/javascript/controllers/undo_controller.js`**

```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="undo"
export default class extends Controller {
  static targets = ["actions", "countdown", "content"]
  static values = { seconds: { type: Number, default: 5 } }

  disconnect() {
    clearInterval(this.interval)
  }

  start(e) {
    if (this.contentTarget.value.length) {
      e.preventDefault()

      this.showActions()
      this.startCountdown()
    }
  }

  startCountdown() {
    this.countdownTarget.textContent = this.secondsValue
    this.interval = setInterval(() => {
      this.secondsValue -= 1

      this.countdownTarget.textContent = this.secondsValue
      console.log('Hello')
      if (this.secondsValue === 0) {
        this.element.requestSubmit()
      }
    }, 1000)
  }

  showActions() {
    this.actionsTarget.parentElement.innerHTML = this.actionsTarget.innerHTML
  }
}
```

2. The form lives inside two nested frames (`undo_tweet` → `new_tweet`). The textarea is both the `content` target *and* `data-turbo-permanent`. The preview actions ship to the browser inside an inert `<template>` so no extra request is needed.

**`app/views/tweets/new.html.erb`**

```erb
<div class="mx-auto my-20 flex items-center justify-center max-w-lg">
  <%= turbo_frame_tag "undo_tweet" do %>
    <%= turbo_frame_tag "new_tweet" do %>
      <%= form_with model: @tweet, data: {controller: "undo"} do |f| %>
        <div class="flex">
          <div class="m-2 w-10 py-1">
            <img class="inline-block h-10 w-10 rounded-full" src="https://pbs.twimg.com/profile_images/1121328878142853120/e-rpjoJi_bigger.png" alt="" />
          </div>
          <div class="flex-1 px-2 pt-2 mt-2">
            <%= f.text_area :content, required: true, data: {"undo-target": "content", "turbo-permanent": true}, class: "border-none focus:ring-0 bg-transparent text-gray-400 font-medium text-lg w-full", rows: 2, cols: 50, placeholder: "What's happening?" %>
          </div>
        </div>

        <div class="flex">
          <div class="w-10"></div>

          <div class="w-64 px-2">
            <!-- image / gif / poll / emoji icon buttons (static markup) -->
          </div>

          <div class="flex-1 flex items-center space-x-3">
            <%= f.submit "Tweet", data: {action: "undo#start"}, class: "bg-blue-400 hover:bg-blue-600 text-white font-bold py-2 px-8 rounded-full mr-8 float-right cursor-pointer" %>
          </div>

          <template data-undo-target="actions">
            <div class="flex w-full items-center justify-between">
              <div>
                <span data-undo-target="countdown"></span>
                <span> Sending Tweet... </span>
              </div>
              <div class="flex items-center space-x-3">
                <%= f.submit "Send now", class: "appearance-none text-blue-400 font-bold cursor-pointer" %>
                <%= link_to "Undo", new_tweet_path, class: "bg-blue-400 hover:bg-blue-600 text-white font-bold py-2 px-8 rounded-full mr-8 float-right" %>
              </div>
            </div>
          </template>
        </div>
      <% end %>
    <% end %>
  <% end %>
</div>
```

3. The controller actions are the default scaffold: `create` redirects to `show`, and `show` renders inside the same `new_tweet` frame — so a successful send replaces the form with the posted tweet.

**`app/views/tweets/show.html.erb`**

```erb
<%= turbo_frame_tag "new_tweet" do %>
  <div class="flex">
    <div class="m-2 w-10 py-1">
      <img class="inline-block h-10 w-10 rounded-full" src="https://pbs.twimg.com/profile_images/1121328878142853120/e-rpjoJi_bigger.png" alt="" />
    </div>
    <div class="flex-1 px-2 pt-2 mt-2">
      <p>
        <%= @tweet.content %>
      </p>
    </div>
  </div>
<% end %>
```

**`app/controllers/tweets_controller.rb`** (changed lines)

```ruby
def create
  @tweet = Tweet.new(tweet_params)

  if @tweet.save
    redirect_to @tweet
  else
    render :new, status: :unprocessable_entity
  end
end

# ...

  # Only allow a list of trusted parameters through.
  def tweet_params
    params.require(:tweet).permit(:content)
  end
```

**Why it matters / when to use:** "Undo" affordances (send later, delayed delete, optimistic actions) without optimistic client state. The reusable insights: `<template>` for markup you'll need later without a round trip, `requestSubmit()` to submit a form from JS while keeping Turbo in charge, and `data-turbo-permanent` to keep user input alive across a frame reload.

`Pattern:` stimulus, stimulus-targets, stimulus-values, turbo-frames, turbo-permanent, forms

---

## Day 18 — Markdown editor with live preview

**Source:** https://x.com/itsameandrea/status/1633526402447204356  ·  **Date:** 2023-03-08  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/39307020749c8ce21bd5023f9c0b18c6d71c8f27

A split-pane markdown editor whose right-hand preview updates as you type — and, unlike the Vue equivalent, persists everything to the database along the way. No markdown parser in the browser: the `autosubmit` controller PATCHes the post on every keystroke, `update` redirects to `show`, and because the form is wired to the preview frame via `data: { turbo_frame: dom_id(@post) }`, only the preview pane swaps. Rendering is done server-side by `redcarpet`.

### How it works

1. Configure the markdown renderer once as a constant.

**`Gemfile`**

```ruby
gem "redcarpet", "~> 3.6"
```

**`config/initializers/markdown.rb`**

```ruby
MARKDOWN = Redcarpet::Markdown.new(Redcarpet::Render::HTML, autolink: true, tables: true)
```

2. The "new" page is a single button that creates an empty post and redirects into the editor — so the editor always has a persisted record to PATCH.

**`app/views/posts/new.html.erb`**

```erb
<%= turbo_frame_tag "markdown_preview" do %>
  <%= button_to "Add post", posts_path, class: "bg-indigo-600 rounded-lg p-3 text-white" %>
<% end %>
```

3. The editor: form on the left, a frame pointing at the post's `show` on the right. The form's `data-turbo-frame` targets `dom_id(@post)` so submissions repaint only the preview.

**`app/views/posts/edit.html.erb`**

```erb
<%= turbo_frame_tag "markdown_preview" do %>
  <div class="flex">
    <div class="w-1/2 p-10">
      <%= form_with model: @post, data: {controller: "autosubmit", turbo_frame: dom_id(@post)} do |f| %>

        <div class="col-span-3 sm:col-span-2">
          <%= f.label :title, class: "block text-sm font-medium leading-6 text-gray-900" %>
          <div class="mt-2 flex rounded-md shadow-sm">
            <%= f.text_field :title, data: {action: "input->autosubmit#submit"}, class: "block w-full flex-1 rounded-md border-0 py-1.5 text-gray-900 ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6" %>
          </div>
        </div>

        <div class="col-span-3 sm:col-span-2">
          <%= f.label :body, class: "block text-sm font-medium leading-6 text-gray-900" %>
          <div class="mt-2">
            <%= f.text_area :body, rows: 3, data: {action: "input->autosubmit#submit"}, class: "block w-full rounded-md border-0 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:py-1.5 sm:text-sm sm:leading-6" %>
          </div>
        </div>
      <% end %>
    </div>
    <div class="w-1/2 p-10 bg-gray-100">
      <%= turbo_frame_tag dom_id(@post), src: post_path(@post) %>
    </div>
  </div>
<% end %>
```

4. `show` renders the parsed HTML inside the matching frame.

**`app/views/posts/show.html.erb`**

```erb
<%= turbo_frame_tag dom_id(@post) do %>
  <div id="markdown" class="whitespace-pre-line leading-none">
    <h1 class="text-2xl font-bold"><%= @post.title %></h1>
    <%= @body.try(:html_safe) %>
  </div>
<% end %>
```

**`app/controllers/posts_controller.rb`**

```ruby
class PostsController < ApplicationController
  def new
    @post = Post.new
  end

  def create
    @post = Post.create!
    redirect_to edit_post_path(@post)
  end

  def edit
    @post = Post.find(params[:id])
  end

  def update
    @post = Post.find(params[:id])
    @post.update(post_params)

    redirect_to @post
  end

  def show
    @post = Post.find(params[:id])
    @body = MARKDOWN.render(@post.body)
  end

  private

  def post_params
    params.require(:post).permit(:title, :body)
  end
end
```

**`app/assets/stylesheets/application.tailwind.css`**

```css
#markdown ul {
  list-style-type: disc;
}
```

**`config/routes.rb`**

```ruby
resources :posts, only: %i[new create edit update show]
```

**Why it matters / when to use:** Any "live preview" pane — markdown, email templates, invoice/PDF previews, code output. The generalisable move is a form whose `data-turbo-frame` points at a *sibling* frame that renders the server's interpretation of the input, with autosave for free.

`Pattern:` turbo-frames, autosubmit, forms, stimulus

---

## Day 19 — Pulse loading state for lazy Turbo Frames

**Source:** https://x.com/itsameandrea/status/1633883152497115148  ·  **Date:** 2023-03-09  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/1a76bae8a343c1ee5c4b61a02dd881f4a4926534

Skeleton screens for free. A `turbo_frame_tag` with an `src` accepts a **block**, and whatever is in that block is rendered immediately and stays on screen until the server response arrives. Put a skeleton partial in the block — here, the real table's markup with `animate-pulse` and empty grey bars — and you get a proper loading state with no JavaScript and no state machine.

### How it works

1. Pass a block to the lazy frame. That block *is* the loading state.

**`app/views/pages/kitchensink.html.erb`**

```erb
<%= render "shared/divider", title: "Day 19/30 - Pulse" %>

<div class="mx-auto my-20 flex items-center justify-center">
  <%= turbo_frame_tag "slow_characters", src: slow_characters_path, class: "w-full" do %>
    <%= render 'slow_characters/loading_index' %>
  <% end %>
</div>
```

2. The skeleton is the real page's chrome with a pulsing table body. The `<% 5.times do %>` / `<% 6.times do %>` loops generate the placeholder grid.

**`app/views/slow_characters/_loading_index.html.erb`** (table portion; the header and filter markup above it mirrors the real view)

```erb
<div class="flow-root">
  <div class="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
    <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
      <table class="min-w-full divide-y divide-gray-300 animate-pulse">
        <thead>
          <tr>
            <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Image</th>
            <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Name</th>
            <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Species</th>
            <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Homeworld</th>
            <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Affiliation</th>
            <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Actions</th>
          </tr>
        </thead>
        <tbody class="divide-y divide-gray-200">
          <% 5.times do %>
            <tr>
              <% 6.times do %>
                <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                  <div class="h-3 bg-gray-100 rounded w-full"></div>
                </td>
              <% end %>
            </tr>
          <% end %>
        </tbody>
      </table>
    </div>
  </div>
</div>
```

3. The controller is a copy of the Day 7 filtered index with an artificial `sleep 5` to make the state visible. In reality this would be a slow query or an external API call.

**`app/controllers/slow_characters_controller.rb`**

```ruby
class SlowCharactersController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @characters = pagy(Character.search(params), items: 5)

    @species = Character.pluck(:species).uniq
    @homeworlds = Character.pluck(:homeworld).uniq
    @affiliations = Character.pluck(:affiliation).uniq

    sleep 5
  end
end
```

**`config/routes.rb`**

```ruby
resources :slow_characters, only: %i[index]
```

**Why it matters / when to use:** Any lazy frame that fronts something slow. A spinner works too — the mechanism is the frame's block content, not the specific markup. Pair this with Day 5's self-replacing frame and Day 25's per-item lazy frames to keep first paint fast.

`Pattern:` turbo-frames, lazy-frames, animation

---

## Day 20 — Dynamic (dependent) select fields

**Source:** https://x.com/itsameandrea/status/1634244554462248972  ·  **Date:** 2023-03-10  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/5f6b8aaa2a4863b86ff415000a9a512b20f6e284

The classic country→state / job→specialization problem, solved without a JSON endpoint. Wrap the form in a Turbo Frame, auto-submit it on `change`, and let the controller decide which options the dependent select gets. The subtle bit: reloading the frame would normally reset the first select too, so it's marked **`data-turbo-permanent`** to survive the swap.

### How it works

1. Ordinary associations.

**`app/models/job.rb`**

```ruby
class Job < ApplicationRecord
  has_many :specializations

  accepts_nested_attributes_for :specializations, allow_destroy: true
end
```

**`app/models/specialization.rb`**

```ruby
class Specialization < ApplicationRecord
  belongs_to :job
end
```

**`app/models/profile.rb`**

```ruby
class Profile < ApplicationRecord
  belongs_to :job
  belongs_to :specialization
end
```

2. The controller filters the dependent collection off a query param, and returns an empty array when nothing is picked (which also drives the `disabled:` state).

**`app/controllers/profiles_controller.rb`**

```ruby
class ProfilesController < ApplicationController
  def index
    @jobs = Job.all
    @specializations = params[:job].present? ? Specialization.where(job_id: params[:job]) : []
  end
end
```

3. The form is a GET form inside the frame, auto-submitting on `change`. `"turbo-permanent": true` on the job select is what keeps the user's choice visible after the frame reloads.

**`app/views/profiles/index.html.erb`**

```erb
<%= turbo_frame_tag "dynamic_select_inputs" do %>
  <%= form_tag profiles_path, method: :get, data: { controller: "autosubmit" } do %>
    <div class="flex space-x-10">
      <div>
        <%= label_tag :job, nil, class: "block text-sm font-medium leading-6 text-gray-900" %>
        <%= select_tag :job,
          options_from_collection_for_select(@jobs, "id", "name"),
          data: { action: "change->autosubmit#submit", "turbo-permanent": true },
          prompt: "Pick a job",
          class: "mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6" %>
      </div>

      <div>
        <%= label_tag :specialization, nil, class: "block text-sm font-medium leading-6 text-gray-900" %>
        <%= select_tag :specialization,
          options_from_collection_for_select(@specializations, "id", "name"),
          disabled: @specializations.empty?,
          prompt: "Pick a specialization",
          class: "mt-2 block w-full rounded-md border-0 py-1.5 pl-3 pr-10 text-gray-900 ring-1 ring-inset ring-gray-300 focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6" %>
      </div>
    </div>
  <% end %>
<% end %>
```

**`app/views/pages/kitchensink.html.erb`** (host page)

```erb
<%= render "shared/divider", title: "Day 20/30 - Dynamic select inputs" %>

<div class="mx-auto my-20 flex items-start justify-center max-w-lg min-h-[500px]">
  <%= turbo_frame_tag "dynamic_select_inputs", src: profiles_path, class: "w-full" %>
</div>
```

**`config/routes.rb`**

```ruby
resources :profiles, only: %i[index]
```

**Caveat from the thread:** this relies on the form being a `GET`. If the dependent selects are part of a `POST`/`PATCH` form, this approach won't work — Andrea points to [Chris Oliver's video](https://www.youtube.com/watch?v=ReZS6wfh3lo) for that variant.

**Why it matters / when to use:** Dependent dropdowns are one of the most common reasons teams reach for a JS framework. Here the option list stays in Ruby, there's no serializer, no fetch, no client-side cache invalidation — just a frame reload plus one permanent element.

`Pattern:` turbo-frames, autosubmit, forms, turbo-permanent, stimulus

---

## Day 21 — Searchable dropdown input

**Source:** https://x.com/itsameandrea/status/1634665897582379010  ·  **Date:** 2023-03-11  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/bcf5549008f4e2de134655270e1a3078c12a2221

A dropdown menu (built on the `tailwindcss-stimulus-components` Dropdown controller) that contains its own live search box for filtering a long list of checkboxes — a pizza topping picker in this case. Because the dropdown is nested inside an outer form, it can't simply be a Turbo Frame pointed at a search action (frames don't compose cleanly with an enclosing form submission), so a small Stimulus controller fires the search as a manual `GET` request via `@rails/request.js` and asks for a `turbo-stream` response instead. The server always re-renders the checkbox partials unchecked, so the controller keeps the "currently checked" state client-side in a JS `Set` and listens for the `turbo:before-stream-render` event to re-apply `checked` to any box in the freshly streamed HTML before it lands in the DOM.

### How it works

1. Register the `dropdown` controller from the `tailwindcss-stimulus-components` gem (for open/close behaviour) and the new `searchable-dropdown` controller.

**`app/javascript/controllers/application.js`**

```js
import { Application } from "@hotwired/stimulus"
import { Dropdown } from "tailwindcss-stimulus-components"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

application.register('dropdown', Dropdown)

export { application }
```

**`app/javascript/controllers/index.js`**

```js
import SearchableDropdownController from "./searchable_dropdown_controller"
application.register("searchable-dropdown", SearchableDropdownController)
```

2. The `searchable-dropdown` controller does two things: on `change` (typing in the search box) it issues a `get` request to the toppings endpoint asking for a turbo-stream response; on `select` (clicking a checkbox) it tracks checked values in a `Set`. A document-level `turbo:before-stream-render` listener re-checks any box in the incoming stream template whose value is already in that `Set`, since the server has no idea what was previously checked.

**`app/javascript/controllers/searchable_dropdown_controller.js`**

```js
import { Controller } from "@hotwired/stimulus"
import { get } from "@rails/request.js"

// Connects to data-controller="searchable-dropdown"
export default class extends Controller {
  static values = {
    url: String,
    attribute: String
  }
  
  connect() {
    this.selected = new Set()
    this.setupEventListener()
  }

  change(e) {
    get(`${this.urlValue}?${this.attributeValue}=${e.target.value}`, {
      responseKind: "turbo-stream"
    })
  }

  select(e) {
    const ingredient = e.target.value

    if (e.target.checked) {
      this.selected.add(ingredient)
    } else {
      this.selected.delete(ingredient)
    }
  }

  setupEventListener() {
    document.addEventListener("turbo:before-stream-render", (event) => {
      const turboStreamElement = event.target
      const {action, target} = turboStreamElement
      const template = turboStreamElement.firstElementChild
      
      if (action === 'update') {
        template.content.querySelectorAll('input[type="checkbox"]').forEach((checkbox) => {
          if (this.selected.has(checkbox.value)) {
            checkbox.checked = true
          }
        })
      }
    })
  }
}
```

3. The view wires the `dropdown` controller to the toggle button, and instantiates `searchable-dropdown` directly on the dropdown menu element, passing in the search URL and the query-param attribute name as Stimulus values. The text input's `change` action fires the search; each checkbox's `change` action tracks selection.

**`app/views/pizzas/index.html.erb`**

```erb
  <%= form_tag pizzas_path, method: :get, class: "mb-20" do %>
    <div data-controller="dropdown">
      <%= label_tag :toppings, "Toppings", class: "block text-sm font-medium leading-6 text-gray-900" %>
      <div class="relative mt-2">
        <button type="button" data-action="click->dropdown#toggle click@window->dropdown#hide" class="relative w-full cursor-default rounded-md bg-white py-1.5 pl-3 pr-10 text-left text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 focus:outline-none focus:ring-2 focus:ring-indigo-600 sm:text-sm sm:leading-6" aria-haspopup="listbox" aria-expanded="true" aria-labelledby="listbox-label">
          <span class="block truncate">Select the toppings you like</span>
          <span class="pointer-events-none absolute inset-y-0 right-0 flex items-center pr-2">
            <svg class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
              <path fill-rule="evenodd" d="M10 3a.75.75 0 01.55.24l3.25 3.5a.75.75 0 11-1.1 1.02L10 4.852 7.3 7.76a.75.75 0 01-1.1-1.02l3.25-3.5A.75.75 0 0110 3zm-3.76 9.2a.75.75 0 011.06.04l2.7 2.908 2.7-2.908a.75.75 0 111.1 1.02l-3.25 3.5a.75.75 0 01-1.1 0l-3.25-3.5a.75.75 0 01.04-1.06z" clip-rule="evenodd" />
            </svg>
          </span>
        </button>

        <div
          data-dropdown-target="menu"
          data-controller="searchable-dropdown"
          data-searchable-dropdown-url-value="<%= toppings_path %>"
          data-searchable-dropdown-attribute-value="name"
          class="hidden absolute p-6 z-10 mt-1 max-h-60 w-full overflow-auto rounded-md bg-white text-base shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none sm:text-sm">
          <input
            type="text"
            name="topping_name"
            data-action="searchable-dropdown#change"
            class="block w-full rounded-md mb-6 border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6" placeholder="Mozzarella">  
          
          <div class="space-y-5" id="topping_options">
            <% @toppings.each do |topping| %>
              <%= render 'topping_option', topping: topping %>
            <% end %>
          </div>
        </div>
      </div>
    </div>
  <% end %>
```

**`app/views/pizzas/_topping_option.html.erb`**

```erb
<div class="relative flex items-start">
  <div class="flex h-6 items-center">
    <%= check_box_tag :topping_name,
      topping.name,
      false,
      data: { action: "change->searchable-dropdown#select" },
      class: "h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600" %>
  </div>
  <div class="ml-3 text-sm leading-6">
    <%= label_tag :topping_name, topping.name, class: "font-medium text-gray-900" %>
  </div>
</div>
```

4. The toppings endpoint searches by name and only ever responds with a turbo stream, which re-renders the same checkbox partial list.

**`app/models/topping.rb`**

```ruby
class Topping < ApplicationRecord
  has_many :pizza_toppings
  has_many :pizzas, through: :pizza_toppings

  scope :filter_by_name, -> (name) { where("name ILIKE ?", "%#{name}%") }

  def self.search(params)
    toppings = all
    toppings = toppings.filter_by_name(params[:name]) if params[:name].present?

    toppings
  end
end
```

**`app/controllers/toppings_controller.rb`**

```ruby
class ToppingsController < ApplicationController
  def index
    @toppings = Topping.search(params)

    respond_to do |format|
      format.turbo_stream
    end
  end
end
```

**`app/views/toppings/index.turbo_stream.erb`**

```erb
<%= turbo_stream.update "topping_options" do %>
  <% @toppings.each do |topping| %>
    <%= render "pizzas/topping_option", topping: topping %>
  <% end %>
<% end %>
```

5. The host page just needs `@toppings` for the initial render; the pizza/topping join models exist for later tips and aren't part of this search mechanism.

**`app/controllers/pizzas_controller.rb`**

```ruby
class PizzasController < ApplicationController
  def index
    @toppings = Topping.limit(5)
  end
end
```

**`config/routes.rb`**

```ruby
resources :pizzas, only: %i[index]
resources :toppings, only: %i[index]
```

**Why it matters / when to use:** This is the pattern for any "checkbox list with a search box" dropdown that lives inside a larger form — where a plain nested Turbo Frame would fight with the enclosing form. Manually firing a `turbo-stream` request from Stimulus and reconciling client-side state against `turbo:before-stream-render` is the escape hatch whenever the server can't be the sole source of truth for UI state.

`Pattern:` turbo-streams, stimulus, stimulus-values, search-filter, forms, third-party-js

---

## Day 22 — Kanban board with drag and drop

**Source:** https://x.com/itsameandrea/status/1634975739744514049  ·  **Date:** 2023-03-12  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/1a3b2e8ceabeb60a7e947da0abf244d8edfae1dd

A multi-column Kanban board where cards can be dragged between columns and reordered within a column, backed by the `sortablejs` JS library for the drag interaction and the `acts_as_list` gem for server-side position bookkeeping. A single Stimulus controller instantiates one `Sortable` per column and links them together with a shared `group`, so SortableJS itself handles cross-column dragging entirely client-side; when a drag ends, the controller fires one `PUT` request (via `@rails/request.js`) with the card's new column and position, and `acts_as_list` takes care of shuffling every other card's position server-side. The response is a tiny turbo-stream flash update — no client state beyond what SortableJS already tracks in the DOM.

### How it works

1. Add the `acts_as_list` gem (mentioned inline — no code block needed) and register a new `kanban` Stimulus controller.

**`app/javascript/controllers/index.js`**

```js
import KanbanController from "./kanban_controller"
application.register("kanban", KanbanController)
```

2. The controller has one `column` target per Kanban column and a `group` value shared across them. On connect, it instantiates a `Sortable` for every column target, all sharing the same `group` so SortableJS allows dragging cards between them.

3. On `onEnd` (drag finished), it reads the dropped element's `data-url`, and `PUT`s the new column id (from the destination column's `data-column-id`) and the new zero-based `newIndex` shifted by `+1` since `acts_as_list` positions are 1-indexed.

**`app/javascript/controllers/kanban_controller.js`**

```js
import { Controller } from "@hotwired/stimulus"
import Sortable from 'sortablejs'
import { put } from "@rails/request.js"

// Connects to data-controller="kanban"
export default class extends Controller {
  static targets = [ "column" ]
  static values = {
    group: String
  }

  connect() {
    this.setupSortable()
  }

  setupSortable() {
    this.columnTargets.forEach((column) => {
      new Sortable(column, {
        group: this.groupValue,
        onEnd: this.onEnd.bind(this)
      })
    })
  }

  onEnd(event) {
    const {from, to, oldIndex, newIndex, clone} = event

    put(clone.dataset.url, {
      responseKind: "turbo-stream",
      body: {
        kanban_column_id: to.dataset.columnId,
        position: newIndex + 1
      }
    })
  }
}
```

4. The view sets `data-controller="kanban"` and a per-board `data-kanban-group-value` (parameterized board title, so multiple boards on a page don't cross-pollinate). Each column div is a `column` target carrying its own `data-column-id`; each card carries the `data-url` used for the `PUT`.

**`app/views/kanban_boards/show.html.erb`**

```erb
<%= turbo_frame_tag "kanban" do %>

  <div class="p-10">
    <h1 class="text-xl font-bold mb-10"> <%= @board.title %> Kanban Board</h1>
    <div
      class="flex justify-between space-x-4"
      data-controller="kanban"
      data-kanban-group-value="<%= @board.title.parameterize %>">
      <% @board.kanban_columns.each do |column| %>
        <div class="w-1/3 bg-gray-100 p-4 flex flex-col">
          <h2 class="text-lg font-bold mb-4"><%= column.title %></h2>
          <div
            class="flex flex-col space-y-4 flex-grow"
            data-column-id="<%= column.id %>"
            data-kanban-target="column">
            <% column.kanban_cards.each do |card| %>
              <div
                class="text-gray-700 p-3 bg-white cursor-grab active:cursor-grabbing"
                data-url="<%= kanban_card_path(card) %>">
                <h4 class="font-medium"><%= card.title %></h4>
              </div>
            <% end %>
          </div>
        </div>
      <% end %>
    </div>
  </div>

<% end %>
```

5. `KanbanCard` uses `acts_as_list` scoped to its column — moving a card automatically renumbers every other card in the source and destination columns. `KanbanColumn` always loads its cards ordered by position.

**`app/models/kanban_card.rb`**

```ruby
class KanbanCard < ApplicationRecord
  belongs_to :kanban_column
  acts_as_list scope: :kanban_column
end
```

**`app/models/kanban_column.rb`**

```ruby
class KanbanColumn < ApplicationRecord
  belongs_to :kanban_board
  has_many :kanban_cards, -> { order(position: :asc) }, dependent: :destroy 
end
```

**`app/models/kanban_board.rb`**

```ruby
class KanbanBoard < ApplicationRecord
  has_many :kanban_columns, dependent: :destroy
end
```

6. The update endpoint just saves the new column/position and flashes a confirmation via turbo stream; `acts_as_list` does the heavy lifting invisibly inside `update`.

**`app/controllers/kanban_cards_controller.rb`**

```ruby
class KanbanCardsController < ApplicationController
  def update
    @card = KanbanCard.find(params[:id])
    
    if @card.update(card_params)
      flash.now[:notice] = "Kanban board updated"
    end
  end

  private

  def card_params
    params.require(:kanban_card).permit(:kanban_column_id, :position)
  end
end
```

**`app/views/kanban_cards/update.turbo_stream.erb`**

```erb
<%= turbo_stream.update "flash", partial: "shared/flash" %>
```

**`config/routes.rb`**

```ruby
resources :kanban_boards, only: %i[show]
resources :kanban_columns, only: %i[update]
resources :kanban_cards, only: %i[update]
```

**Why it matters / when to use:** Whenever a UI needs genuinely client-side drag physics (auto-scroll, ghost elements, cross-container reordering) that Turbo can't fake with server round-trips, the right split is: let a focused JS library (SortableJS here) own the drag gesture entirely, and use Stimulus only as the thin bridge that turns the *result* of the drag into one Rails request. `acts_as_list` removes the need to hand-roll position renumbering.

`Pattern:` drag-drop, stimulus, stimulus-targets, stimulus-values, turbo-streams, turbo-frames, flash, third-party-js

---

## Day 23 — Real-time notifications with the noticed gem

**Source:** https://x.com/itsameandrea/status/1635359450545659904  ·  **Date:** 2023-03-13  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/7554db8046804bd8343c14146053e70fda85bb2a

A follow-a-user feature that pushes a live notification (list item + unread red dot) to the followed user's browser the instant they get followed, with no polling. The `noticed` gem models each notification as its own class (`NewFollowerNotification`) and persists a `Notification` record for the recipient; that record's own `after_create_commit` callback broadcasts two `turbo_stream` appends — the notification text and a red-dot badge — to a per-user stream named `"notifications_#{recipient.id}"`. Any page the recipient has open that calls `turbo_stream_from` on that same stream name receives the update over Action Cable and patches the DOM automatically, with zero client-side JS beyond Turbo's built-in stream handling.

> Note: the diff below carries a small bug from the original commit — `broadcast_append_to("notifications_#{recipient.id}"` is missing a trailing comma before the `target:` keyword arg. It's fixed one day later, in the Day 24 diff.

### How it works

1. Add the `noticed` gem, then define a `Follow` join model between two users. Its `after_create_commit` kicks off the notification.

**`Gemfile`** (addition)

```ruby
gem "noticed", "~> 1.6"
```

**`app/models/follow.rb`**

```ruby
class Follow < ApplicationRecord
  belongs_to :followed_user, class_name: 'User'
  belongs_to :follower, class_name: 'User'

  after_create_commit :send_notification

  private

  def send_notification
    NewFollowerNotification.with(follow: self).deliver_later(followed_user)
  end
end
```

2. `NewFollowerNotification` is a `Noticed::Base` subclass: it declares how it's delivered (`:database`, i.e. persisted as a `Notification` row) and what message to render.

**`app/notifications/new_follower_notification.rb`**

```ruby
# To deliver this notification:
#
# NewFollower.with(post: @post).deliver_later(current_user)
# NewFollower.with(post: @post).deliver(current_user)

class NewFollowerNotification < Noticed::Base
  deliver_by :database

  param :follow

  def message
    "#{params[:follow].follower.username} is now a follower!"
  end
end
```

3. The `noticed` gem writes to a `Notification` table (via `include Noticed::Model`). Its own `after_create_commit` is where the real-time push happens: two `broadcast_append_to` calls target the recipient's personal stream, one appending the notification text into the dropdown list, one appending a red-dot badge onto the bell icon.

**`app/models/notification.rb`**

```ruby
class Notification < ApplicationRecord
  include Noticed::Model
  belongs_to :recipient, polymorphic: true

  after_create_commit :broadcast_to_recipient

  def broadcast_to_recipient
    broadcast_append_to(
      "notifications_#{recipient.id}"
      target: "notifications_list",
      partial: "notifications/notification",
      locals: {
        notification: self
      }
    )

    broadcast_append_to(
      "notifications_#{recipient.id}",
      target: "notifications_icon",
      partial: "notifications/red_dot"
    )
  end
end
```

**`app/views/notifications/_notification.html.erb`**

```erb
<span class="block px-4 py-2 text-sm text-gray-700"> <%= notification.to_notification.message %> </span>
```

**`app/views/notifications/_red_dot.html.erb`**

```erb
<div class="h-2 w-2 rounded-full bg-red-500 absolute top-0 right-0">
</div>
```

4. `User` grows the follower/followee associations plus a polymorphic `has_many :notifications` as the recipient side.

**`app/models/user.rb`** (additions)

```ruby
  has_many :notifications, as: :recipient, dependent: :destroy

  has_many :followees, foreign_key: :follower_id, class_name: "Follow", dependent: :destroy
  has_many :followed_users, through: :followees

  has_many :following_users, foreign_key: :followed_user_id, class_name: "Follow", dependent: :destroy
  has_many :followers, through: :following_users
```

5. The user's profile page subscribes to their own notification stream with `turbo_stream_from`, renders the notification bell/dropdown (only when viewing your own profile), and exposes a `button_to` to follow the profile owner, scoped inside its own `follow` turbo frame.

**`app/views/users/show.html.erb`**

```erb
<%= turbo_frame_tag "user_notifications" do %>
  <% if current_user %>
    <%= turbo_stream_from "notifications_#{current_user.id}" %>
  <% end %>

  <nav class="bg-gray-800">
    <div class="mx-auto max-w-7xl px-2 sm:px-6 lg:px-8">
      <div class="relative flex h-16 items-center justify-between">
        <div class="flex flex-1 items-center justify-center sm:items-stretch sm:justify-start">
          <div class="flex flex-shrink-0 items-center">
            <img class="block h-8 w-auto lg:hidden" src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=500" alt="Your Company">
            <img class="hidden h-8 w-auto lg:block" src="https://tailwindui.com/img/logos/mark.svg?color=indigo&shade=500" alt="Your Company">
          </div>
        </div>
        <div class="absolute inset-y-0 right-0 flex items-center pr-2 sm:static sm:inset-auto sm:ml-6 sm:pr-0">
          <div class="relative ml-3" data-controller="dropdown">
            <button data-action="click->dropdown#toggle click@window->dropdown#hide" id="notifications_icon" type="button" class="rounded-full relative bg-gray-800 p-1 text-gray-400 hover:text-white focus:outline-none focus:ring-2 focus:ring-white focus:ring-offset-2 focus:ring-offset-gray-800">
              <span class="sr-only">View notifications</span>
              <svg class="h-6 w-6" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" aria-hidden="true">
                <path stroke-linecap="round" stroke-linejoin="round" d="M14.857 17.082a23.848 23.848 0 005.454-1.31A8.967 8.967 0 0118 9.75v-.7V9A6 6 0 006 9v.75a8.967 8.967 0 01-2.312 6.022c1.733.64 3.56 1.085 5.455 1.31m5.714 0a24.255 24.255 0 01-5.714 0m5.714 0a3 3 0 11-5.714 0" />
              </svg>
            </button>

            <% if @user == current_user %>
              <div data-dropdown-target="menu" id="notifications_list" class="absolute right-0 z-10 mt-2 w-48 origin-top-right rounded-md bg-white py-1 shadow-lg ring-1 ring-black ring-opacity-5 focus:outline-none" role="menu" aria-orientation="vertical" aria-labelledby="user-menu-button" tabindex="-1">
                <% if @user.notifications.any? %>
                  <div id="notifications">
                    <% @user.notifications.each do |notification| %>
                      <%= render "notifications/notification", notification: notification %>
                    <% end %>
                  </div>
                <% end %>
              </div>
            <% end %>
          </div>
        </div>
      </div>
    </div>
  </nav>
  
  <div class="p-10">
    <h1 class="text-xl font-bold"> <%= @user.username %> Profile </h1>

    <% unless @user == current_user %>
      <%= turbo_frame_tag "follow" do %>
        <%= button_to "Follow #{@user.username}",
          follows_path(followed_user_id: @user.id),
          method: :post,
          class: "bg-indigo-500 hover:bg-indigo-600 text-white p-3 rounded-lg mt-5" %>
      <% end %>
    <% end %>
  </div>
<% end %>
```

6. `FollowsController#create` just creates the row (the notification fires from the model callback) and renders a small success banner inside the `follow` frame from step 5.

**`app/controllers/follows_controller.rb`**

```ruby
class FollowsController < ApplicationController
  def create
    @follow = Follow.create(follower_id: current_user.id, followed_user_id: params[:followed_user_id])
  end
end
```

**`app/views/follows/create.html.erb`**

```erb
<%= turbo_frame_tag "follow" do %>
  <div class="rounded-md bg-green-50 p-4">
    <div class="flex">
      <div class="flex-shrink-0">
        <svg class="h-5 w-5 text-green-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
          <path fill-rule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z" clip-rule="evenodd" />
        </svg>
      </div>
      <div class="ml-3">
        <h3 class="text-sm font-medium text-green-800">You're now following <%= @follow.followed_user.username %></h3>
      </div>
    </div>
  </div>
<% end %>
```

**`app/controllers/users_controller.rb`**

```ruby
class UsersController < ApplicationController
  def show
    @user = User.find(params[:id])
  end
end
```

**`config/routes.rb`**

```ruby
resources :users, only: %i[show]
resources :follows, only: %i[create]
```

**Why it matters / when to use:** This is the template for any "push a live update to one specific user" feature (mentions, DMs, alerts) — persist the event with a service object/gem, broadcast from the model's own commit callback to a per-recipient stream name, and let any open view that subscribes via `turbo_stream_from` receive it for free over Action Cable.

`Pattern:` notifications, broadcasts, actioncable, turbo-streams, turbo-frames, third-party-js

---

## Day 24 — Gmail-style bulk select

**Source:** https://x.com/itsameandrea/status/1635687374238756872  ·  **Date:** 2023-03-14  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/ce607806de688de7c3ea57bb975244e0c620ebf0

A paginated inbox (10 emails per page via `pagy`) that reproduces Gmail's two-stage "select all" pattern: check one box to select everything on the current page, then click a banner link to escalate to selecting every record in the entire table, all without a line of JavaScript. Both selection stages are pure state carried in the URL query string (`select_page`, `select_all`, `selected[]`) — the "select all" checkbox and the "select every email" banner link are just `link_to`s that add those params and reload the page inside the enclosing `bulk_select` Turbo Frame, and the checkbox `checked` attributes are computed server-side from whatever's currently in `params`. Delete then just reads the same params again to know what to destroy.

### How it works

1. `EmailsController#index` paginates with `pagy` and also grabs the total unpaginated count (used in the "select all N emails" banner text).

**`app/controllers/emails_controller.rb`**

```ruby
class EmailsController < ApplicationController
  include Pagy::Backend

  def index
    @pagy, @emails = pagy(Email.all, items: 10)
    @count = Email.count
  end
end
```

**`app/models/email.rb`**

```ruby
class Email < ApplicationRecord
end
```

2. The whole table lives in a `bulk_select` frame. The header checkbox is wrapped in a `link_to` that toggles `select_page` on/off in the URL — reloading the frame with every row's checkbox now defaulting to `checked`. A banner conditionally appears above the table: while only the page is selected, it offers "Select all N emails" (adds `select_all: true`); once `select_all` is set, the banner switches to a delete/clear-selection bar.

**`app/views/emails/index.html.erb`**

```erb
<%= turbo_frame_tag "bulk_select" do %>
  <div class="px-4 sm:p-6 lg:p-8">
    <div class="sm:flex sm:items-center">
      <div class="sm:flex-auto">
        <h1 class="text-base font-semibold leading-6 text-gray-900">Inbox</h1>
      </div>
    </div>
    <div class="mt-8 flow-root">
      <div class="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
          <% if @emails.any? %>
            <div class="relative">
              <% if params[:select_all].present? %>
                <div class="absolute top-0 right-0 left-14 justify-between flex h-12 items-center space-x-3 bg-red-100 pt-1 px-3 sm:left-12">
                  <span></span>
                  <div>
                    <span>All <%= @count %> emails in your inbox have been selected.</span>
                    <%= link_to "Clear selection", emails_path, class: "inline-flex items-center rounded bg-white px-2 py-1 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-30 disabled:hover:bg-white" %>
                  </div>
                  <div>
                    <%= button_to emails_bulk_path(all: true), method: :delete, class: "inline-flex flex items-center items-center rounded bg-red-500 px-2 py-1 text-sm font-semibold text-white shadow-sm hover:bg-red-600 disabled:cursor-not-allowed disabled:opacity-30 disabled:hover:bg-white" do %>
                      <span> Delete selected </span>
                      <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-4 h-4 ml-3">
                        <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
                      </svg>
                    <% end %>
                  </div>
                </div>
              <% elsif params[:select_page].present? %>
                <div class="absolute top-0 left-14 flex h-12 items-center space-x-3 bg-white sm:left-12">
                  <%= link_to "Select all #{@count} emails", emails_path(select_all: true), class: "inline-flex items-center rounded bg-white px-2 py-1 text-sm font-semibold text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 hover:bg-gray-50 disabled:cursor-not-allowed disabled:opacity-30 disabled:hover:bg-white" %>
                </div>
              <% end %>

              <table class="min-w-full table-fixed divide-y divide-gray-300">
                <thead>
                  <tr>
                    <th scope="col" class="relative px-7 sm:w-12 sm:px-6">
                      <%= link_to emails_path(select_page: params[:select_page].present? ? nil : true), class: "absolute left-4 top-1/2 -mt-2" do %>
                        <%= check_box_tag "select_page",
                          false,
                          params[:select_page].present? || params[:select_all].present?,
                          class: "h-4 w-4 cursor-pointer rounded border-gray-300 text-indigo-600 focus:ring-indigo-600" %>
                      <% end %>
                    </th>
                    <th scope="col" class="min-w-[12rem] py-3.5 pr-3 text-left text-sm font-semibold text-gray-900">Subject</th>
                  </tr>
                </thead>
                <tbody class="divide-y divide-gray-200 bg-white">
                  <!-- Selected: "bg-gray-50" -->
                  <% @emails.each do |email| %>
                    <tr>
                      <td class="relative px-7 sm:w-12 sm:px-6">
                        <%= check_box_tag "selected[]",
                          false,
                          params[:selected]&.include?(email.id.to_s) || params[:select_all].present? || params[:select_page].present?,
                          class: "absolute left-4 top-1/2 -mt-2 h-4 w-4 rounded border-gray-300 text-indigo-600 focus:ring-indigo-600" %>
                      </td>
                      
                      <td class="whitespace-nowrap py-4 pr-3 text-sm font-medium text-gray-900"><%= email.subject_line %></td>
                    </tr>
                  <% end %>

                  <!-- More people... -->
                </tbody>
              </table>
            </div>
          <% else %>
            <div class="text-center min-h-[300px] flex flex-col items-center justify-center">
              <h3 class="mt-2 text-2xl font-semibold text-gray-900">Inbox zero! 🎉 🥳</h3>
            </div>
          <% end %>
        </div>
      </div>
    </div>
  </div>
<% end %>
```

3. To keep controllers RESTful, bulk deletion lives in its own namespaced `Emails::Bulk` controller rather than being bolted onto `EmailsController`. It reads either an explicit `ids[]` list or, when `all` is passed, every `Email` — mirroring exactly the "select all N" escalation from the view — then redirects back, which reloads the `bulk_select` frame.

**`app/controllers/emails/bulk_controller.rb`**

```ruby
class Emails::BulkController < ApplicationController
  before_action :set_emails

  def destroy
    Email.destroy_all
    redirect_to emails_path
  end

  private

  def set_emails
    @emails = params[:all] ? Email.all : Email.where(id: params[:ids])
  end
end
```

4. Routes nest the bulk-delete endpoint under an `emails` namespace, kept separate from the plain `emails` resource.

**`config/routes.rb`**

```ruby
resources :emails, only: %i[index]
namespace :emails do
  resource :bulk, only: :destroy, controller: :bulk
end
```

> Also fixed in this commit: yesterday's `Notification#broadcast_to_recipient` (Day 23) was missing a comma after the stream name argument — `"notifications_#{recipient.id}"` now correctly reads `"notifications_#{recipient.id}",`.

**Why it matters / when to use:** Whenever a bulk-action UI needs to represent "everything on this page" vs. "literally every record, including ones not yet rendered," keeping that distinction in the URL (rather than a client-side array of IDs) means the server can always recompute the true selection and the whole UI stays link-driven — no JS state to keep in sync with checkboxes.

`Pattern:` turbo-frames, forms, pagination, search-filter

---

## Day 25 — Reddit-style lazy-loaded nested comments

**Source:** https://x.com/itsameandrea/status/1636064833245417473  ·  **Date:** 2023-03-15  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/bd30fd081fced690c64460bb56ac150a6c8b63a7

An arbitrarily-deep threaded comment system, modeled with nothing more than a self-referential `parent_id` column, where every single comment — top-level or nested reply — is its own lazily-loaded Turbo Frame. The index page only eagerly renders empty `<turbo-frame loading="lazy">` placeholders for each top-level comment; each of those frames, once it loads, recursively renders its own replies as more lazy frames. That recursion is what gives "infinite" nesting without ever fetching a subtree the user hasn't scrolled to. A reply form is likewise its own frame, and comments use `data-turbo-permanent` so that collapsing/expanding replies (via a `hide_replies` query param) only re-renders the toggle icon and the nested replies container, not the whole comment.

### How it works

1. `Comment` is self-referential: a `parent` (optional, for top-level comments) and `replies`. Newest-first ordering is the default scope, and a `top_level` scope filters to root comments for the index page.

**`app/models/comment.rb`**

```ruby
class Comment < ApplicationRecord
  belongs_to :parent, class_name: "Comment", optional: true
  has_many :replies, foreign_key: "parent_id", class_name: "Comment", dependent: :destroy

  default_scope { order(created_at: :desc) }
  scope :top_level, -> { where(parent_id: nil) }
end
```

2. The index page renders the comment count, an eager `new_comment` frame for the top-level comment form, and one lazy-loaded frame per top-level comment (`loading: :lazy` defers the request until the frame scrolls into view).

**`app/controllers/comments_controller.rb`**

```ruby
class CommentsController < ApplicationController
  def index
    @comments = Comment.top_level
    @count = Comment.count
  end

  def new
    @comment = Comment.new
  end

  def create
    @comment = Comment.new(comment_params)

    respond_to do |format|
      if @comment.save
        format.turbo_stream
      end
    end
  end

  def show
    @comment = Comment.find(params[:id])
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end
end
```

**`app/views/comments/index.html.erb`**

```erb
<%= turbo_frame_tag "nested_comments" do %>
  <section class="bg-white py-8 lg:py-16">
    <div class="max-w-2xl mx-auto px-4">
      <div class="flex justify-between items-center mb-6">
        <h2 class="text-lg lg:text-2xl font-bold text-gray-900">Discussion (<span id="comments_count"><%= @count %></span>)</h2>
      </div>

      <%= turbo_frame_tag "new_comment", src: new_comment_path %>

      <div id="comments">
        <% @comments.each do |comment| %>
          <%= turbo_frame_tag dom_id(comment), loading: :lazy, src: comment_path(comment) %>
        <% end %>
      </div>
    </div>
  </section>
<% end %>
```

3. `new`/`create` render the plain comment form inside its own `new_comment` frame. On successful create, a turbo stream updates the live count, swaps in a fresh blank form, and prepends the new comment (as a lazy `comment` partial render, not another lazy frame, since it's already fully in hand).

**`app/views/comments/new.html.erb`**

```erb
<%= turbo_frame_tag "new_comment" do %>
  <%= render "form", comment: @comment %>
<% end %>
```

**`app/views/comments/_form.html.erb`**

```erb
<%= form_with model: comment, class: "mb-6" do |f| %>
  <div class="py-2 px-4 mb-4 bg-white rounded-lg rounded-t-lg border border-gray-200">
    <%= f.label :content, "Your comment", class: "sr-only" %>
    <%= f.text_area :content,
      rows: 6,
      placeholder: "Write a comment...",
      class: "px-0 w-full text-sm text-gray-900 border-0 focus:ring-0 focus:outline-none" %>
  </div>

  <%= f.submit "Add comment", class: "inline-flex items-center py-2.5 px-4 text-xs font-medium text-center text-white bg-indigo-600 rounded-lg cursor-pointer hover:bg-indigo-700" %>
<% end %>
```

**`app/views/comments/create.turbo_stream.erb`**

```erb
<%= turbo_stream.update "comments_count", html: Comment.count %>

<%= turbo_stream.update "new_comment",
  partial: "comments/form",
  locals: { comment: Comment.new }  %>

<%= turbo_stream.prepend "comments",
  partial: "comments/comment",
  locals: { comment: @comment } %>
```

4. `show` (loaded by each lazy frame) renders the recursive `_comment` partial. Inside it: a `data-turbo-permanent` block for the timestamp and body (so they survive frame re-renders untouched), a collapse/expand icon link that toggles `hide_replies` in the URL against `comment_path(comment)` (which reloads *only this comment's frame*), a "Reply" link that targets a dedicated `${dom_id(comment)}_reply` frame, and — when replies aren't hidden — a recursive list of lazy-loaded frames, one per reply, using the exact same pattern as the top level.

**`app/views/comments/show.erb`**

```erb
<%= render "comment", comment: @comment %>
```

**`app/views/comments/_comment.html.erb`**

```erb
<%= turbo_frame_tag dom_id(comment) do %>
  <article class="pl-6 pt-6 mb-6 text-base bg-white rounded-lg">
    <div class="flex justify-between items-center mb-2">
      <div class="flex items-center" data-turbo-permanent>
        <p class="text-sm text-gray-600">
          <%= comment.created_at.strftime("%b. %-d, %Y") %>
        </p>
      </div>
      
      <% if params[:hide_replies].present? %>
        <%= link_to comment_path(comment), class: "inline-flex items-center p-2 text-sm font-medium text-center text-gray-400 bg-white rounded-lg hover:bg-gray-100 focus:ring-4 focus:outline-none focus:ring-gray-50" do %>
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M3.75 3.75v4.5m0-4.5h4.5m-4.5 0L9 9M3.75 20.25v-4.5m0 4.5h4.5m-4.5 0L9 15M20.25 3.75h-4.5m4.5 0v4.5m0-4.5L15 9m5.25 11.25h-4.5m4.5 0v-4.5m0 4.5L15 15" />
          </svg>
        <% end %>
      <% else %>
        <%= link_to comment_path(comment, hide_replies: true), class: "inline-flex items-center p-2 text-sm font-medium text-center text-gray-400 bg-white rounded-lg hover:bg-gray-100 focus:ring-4 focus:outline-none focus:ring-gray-50" do %>
          <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-5 h-5">
            <path stroke-linecap="round" stroke-linejoin="round" d="M9 9V4.5M9 9H4.5M9 9L3.75 3.75M9 15v4.5M9 15H4.5M9 15l-5.25 5.25M15 9h4.5M15 9V4.5M15 9l5.25-5.25M15 15h4.5M15 15v4.5m0-4.5l5.25 5.25" />
          </svg>
        <% end %>
      <% end %>
    </div>
    
    <p class="text-gray-500" data-turbo-permanent>
      <%= comment.content %>
    </p>
    
    <div class="flex items-center mt-4 space-x-4" data-turbo-permanent>
      <%= link_to new_comment_reply_path(comment), data: { turbo_frame: "#{dom_id(comment)}_reply" }, class: "flex items-center text-sm text-gray-500 hover:underline" do %>
        <svg aria-hidden="true" class="mr-1 w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z"></path></svg>
        Reply
      <% end %>
    </div>
    
    <%= turbo_frame_tag "#{dom_id(comment)}_reply", class: "w-full", data: { turbo_permanent: true } %>
    
    <% if comment.replies && params[:hide_replies].nil? %>
      <% comment.replies.each do |reply| %>
        <%= turbo_frame_tag dom_id(reply), loading: :lazy, src: comment_path(reply) %>
      <% end %>
    <% end %>
  </article>
<% end %>
```

5. Replying is deliberately isolated into its own `RepliesController` (nested under `comments`) rather than overloading `CommentsController`, keeping each controller single-purpose. `new` renders the reply form frame for a given parent comment; `create` sets `parent` on the new comment before saving.

**`app/controllers/replies_controller.rb`**

```ruby
class RepliesController < ApplicationController
  def new
    @comment = Comment.new
    @parent = Comment.find(params[:comment_id])
  end

  def create
    @comment = Comment.new(comment_params)
    @comment.parent = Comment.find(params[:comment_id])

    respond_to do |format|
      if @comment.save
        format.turbo_stream
      end
    end
  end

  private

  def comment_params
    params.require(:comment).permit(:content)
  end
end
```

**`app/views/replies/new.html.erb`**

```erb
<%= turbo_frame_tag "#{dom_id(@parent)}_reply", class: "w-full" do %>
  <%= form_with model: @comment, url: comment_replies_path(@parent), class: "mt-6 " do |f| %>
    <div class="py-2 px-4 mb-4 bg-white rounded-lg rounded-t-lg border border-gray-200">
      <%= f.label "Your comment", :content, class: "sr-only" %>
      <%= f.text_area :content,
        rows: 6,
        placeholder: "Write a comment...",
        class: "px-0 w-full text-sm text-gray-900 border-0 focus:ring-0 focus:outline-none" %>
    </div>

    <%= f.submit "Add reply", class: "inline-flex items-center py-2.5 px-4 text-xs font-medium text-center text-white bg-indigo-600 rounded-lg cursor-pointer hover:bg-indigo-700" %>
  <% end %>
<% end %>
```

6. On successful reply creation: bump the global count, replace the (now stale) reply-form frame with a fresh empty one, and render the newly created reply nested right under its parent.

**`app/views/replies/create.turbo_stream.erb`**

```erb
<%= turbo_stream.update "comments_count", html: Comment.count %>

<%= turbo_stream.replace "#{dom_id(@comment.parent)}_reply" do %>
  <%= turbo_frame_tag "#{dom_id(@comment.parent)}_reply", class: "w-full" %>
  <%= render "comments/comment", comment: @comment %>
<% end %>
```

7. Routes nest `replies` under `comments` so reply URLs read as `comment_replies_path`/`new_comment_reply_path`, matching the isolated controller from step 5.

**`config/routes.rb`**

```ruby
resources :comments, only: %i[index new create show] do
  resources :replies, only: %i[new create]
end
```

**Why it matters / when to use:** This is the go-to shape for any deeply/recursively nested resource (threaded comments, nested categories, org charts) where rendering everything up front would be wasteful: make every node its own lazy Turbo Frame that recursively renders more lazy frames for its children, and use `data-turbo-permanent` to shield the parts of a node that don't need to re-render when only a sibling toggle (like collapse state) changes.

`Pattern:` turbo-frames, lazy-frames, turbo-streams, turbo-permanent, forms, nested-forms

---

## Day 26 — Scroll animations with Stimulus + IntersectionObserver

**Source:** https://x.com/itsameandrea/status/1636472606093377549  ·  **Date:** 2023-03-16  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/631dc614caa1c1cc808830a43e7b925ae1cb8e23

Modern landing pages often animate elements into view as the user scrolls. Rather than reaching for a JS animation framework or React, this is done with a single `animate-scroll` Stimulus controller under 40 lines: it tags elements with `opacity-0` on connect, watches them with a native `IntersectionObserver`, and swaps in an animate.css class once each element is 50% visible. The observer (not scroll event listeners) does all the visibility detection, so there's no manual scroll-position math and no jank.

### How it works

1. The controller declares an `animatable` target and an `animation` Stimulus value (defaulting to `animate__slideInUp`, an animate.css class). On `connect()` it prepares targets, then sets up the observer.

**`app/javascript/controllers/animate_scroll_controller.js`**
```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="animate-scroll"
export default class extends Controller {
  static targets = ["animatable"]
  static values = {
    animation: {
      type: String,
      default: "animate__slideInUp"
    }
  }
  
  connect() {
    this.prepareTargets()
    this.setupObserver()
  }

  prepareTargets() {
    this.animatableTargets.forEach(target => {
      target.classList.add('animate__animated', 'opacity-0')
    })
  }

  setupObserver() {
    this.observer = new IntersectionObserver(entries => {
      entries.forEach(entry => {
        if (entry.isIntersecting) {
          entry.target.classList.remove("opacity-0")
          entry.target.classList.add(this.animationValue)

          this.observer.unobserve(entry.target)
        }
      })
    }, { threshold: 0.5 })

    this.animatableTargets.forEach(target => this.observer.observe(target))
  }
}
```

2. The controller is registered like every other Stimulus controller in the app.

**`app/javascript/controllers/index.js`** (addition)
```js
import AnimateScrollController from "./animate_scroll_controller"
application.register("animate-scroll", AnimateScrollController)
```

3. `prepareTargets()` adds `animate__animated` (animate.css's base class, required for any animate.css animation to run) plus `opacity-0` (a Tailwind utility) to every target up front, so elements start invisible.

4. `setupObserver()` creates one `IntersectionObserver` with `{ threshold: 0.5 }`, meaning an element only counts as intersecting once half of it is on screen. When that fires, `opacity-0` is removed and the configured animation class is added, triggering the animate.css keyframe animation; the element is then `unobserve`d so the animation only plays once.

5. On the demo landing page, the whole page opts into the behavior with `data-controller="animate-scroll"` on the root `<div>`, and each section that should animate carries `data-animate-scroll-target="animatable"`. A finer-grained `delayable` target name also appears on the four feature-grid items (for a possible staggered-delay variant), though the controller shown only wires up the `animatable` target.

**`app/views/pages/landing_page.html.erb`** (representative excerpts — full file is a ~520-line Tailwind landing page)
```erb
<div class="bg-white" data-controller="animate-scroll">
  ...
  <main class="isolate">
    <!-- Hero section -->
    <div class="relative pt-14" data-animate-scroll-target="animatable">
      ...
    </div>

    <!-- Logo cloud -->
    <div class="mx-auto max-w-7xl px-6 lg:px-8" data-animate-scroll-target="animatable">
      ...
    </div>

    <!-- Feature section -->
    <div class="mx-auto mt-32 max-w-7xl px-6 sm:mt-56 lg:px-8" data-animate-scroll-target="animatable">
      ...
      <dl class="grid max-w-xl grid-cols-1 gap-y-10 gap-x-8 lg:max-w-none lg:grid-cols-2 lg:gap-y-16">
        <div class="relative pl-16" data-animate-scroll-target="delayable">
          ...
        </div>
        <!-- three more .delayable feature items -->
      </dl>
    </div>

    <!-- Testimonial section -->
    <div class="mx-auto mt-32 max-w-7xl sm:mt-56 sm:px-6 lg:px-8" data-animate-scroll-target="animatable">
      ...
    </div>

    <!-- Pricing section -->
    <div class="py-24 sm:pt-48" data-animate-scroll-target="animatable">
      ...
    </div>

    <!-- FAQs -->
    <div class="mx-auto max-w-2xl divide-y divide-gray-900/10 px-6 pb-8 sm:pt-12 sm:pb-24 lg:max-w-7xl lg:px-8 lg:pb-32" data-animate-scroll-target="animatable">
      ...
    </div>

    <!-- CTA section -->
    <div class="relative -z-10 mt-32 px-6 lg:px-8" data-animate-scroll-target="animatable">
      ...
    </div>
  </main>

  <!-- Footer -->
  <div class="mx-auto mt-32 max-w-7xl px-6 lg:px-8" data-animate-scroll-target="animatable">
    ...
  </div>
</div>
```

6. A new `landing` layout loads the vendored **animate.css** library from a CDN (`https://cdnjs.cloudflare.com/ajax/libs/animate.css/4.1.1/animate.min.css`) alongside the app's own stylesheet/JS bundles; the vendored CSS itself is not hand-written app code and isn't reproduced here. `PagesController` gets a `landing_page` action and a `resolve_layout` `before_action`-style method so that only this action renders under the new `landing` layout instead of `application`.

**`app/controllers/pages_controller.rb`** (additions)
```ruby
class PagesController < ApplicationController
  layout :resolve_layout

  def landing_page
  end

  private

  def resolve_layout
    case action_name
    when "landing_page"
      "landing"
    else
      "application"
    end
  end
end
```

**`config/routes.rb`** (addition)
```ruby
get 'landing_page', to: 'pages#landing_page'
```

**Why it matters / when to use:** Reach for this whenever a marketing/landing page needs "fade or slide in as you scroll" polish without pulling in a JS animation library or reimplementing it in React — the IntersectionObserver plus a couple of CSS classes gets 90% of the effect for near-zero JS.

`Pattern:` stimulus, stimulus-values, stimulus-targets, stimulus-classes, animation

---

## Day 27 — FullCalendar with Stimulus target callbacks

**Source:** https://x.com/itsameandrea/status/1636834860018053122  ·  **Date:** 2023-03-17  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/3fce85719516d17f7094e234bca4c7f01e150b45

This tip wires the FullCalendar JS library up to a Rails CRUD flow using a Stimulus feature that's easy to miss: target lifecycle callbacks. Instead of manually pushing new events into the calendar instance after a create request, each `Event` row rendered to the page is itself a Stimulus target, and Stimulus automatically calls `eventTargetConnected(element)` whenever such a target is inserted into the DOM (including via a Turbo Stream append). That callback reads the event's data attributes and calls FullCalendar's `addEvent`, so the calendar stays in sync with zero custom JS glue beyond the controller itself — the create form's Turbo Stream response only has to append an `<li>`, and the target-connected callback does the rest.

### How it works

1. `calendar_controller.js` targets both the calendar mount point (`calendar`) and individual event rows (`event`). `initialize()` builds the FullCalendar instance immediately so it's ready before any event targets connect.

**`app/javascript/controllers/calendar_controller.js`**
```js
import { Controller } from "@hotwired/stimulus"
import { Calendar } from '@fullcalendar/core'
import dayGridPlugin from '@fullcalendar/daygrid'


// Connects to data-controller="calendar"
export default class extends Controller {
  static targets = ["calendar", "event"]
  
  initialize() {
    this.setupCalendar()
  }

  setupCalendar() {
    this.calendar = new Calendar(this.calendarTarget, {
      plugins: [ dayGridPlugin ],
      initialView: 'dayGridMonth',
      headerToolbar: {
        left: 'prev,next today',
        center: 'title'
      }
    })

    this.calendar.render()
  }

  eventTargetConnected(event) {
    const { id, title, startingAt: start } = event.dataset

    if (this.calendar) {
      const event = {
        id,
        title,
        start: new Date(start),
      }

      this.calendar.addEvent(event)
    }
  }
}
```

**`app/javascript/controllers/index.js`** (addition)
```js
import CalendarController from "./calendar_controller"
application.register("calendar", CalendarController)
```

2. `Event` is a plain ActiveRecord model, always ordered by start time, backing a simple controller with `index`, `new`, and `create` actions. `create` responds with a Turbo Stream template rather than redirecting.

**`app/models/event.rb`**
```ruby
class Event < ApplicationRecord
  default_scope { order(starting_at: :asc) }
end
```

**`app/controllers/events_controller.rb`**
```ruby
class EventsController < ApplicationController
  def index
    @events = Event.all
  end

  def new
    @event = Event.new
  end
  
  def create
    @event = Event.new(event_params)
    
    respond_to do |format|
      if @event.save
        format.turbo_stream
      end
    end
  end

  private

  def event_params
    params.require(:event).permit(:title, :starting_at)
  end
end
```

3. `events#index` renders the calendar and a sidebar: the calendar controller's root div, a lazily-loaded `new_event` turbo frame holding the create form, and an `events` list that the existing events are rendered into on first load.

**`app/views/events/index.html.erb`**
```erb
<%= turbo_frame_tag "calendar_callbacks" do %>
  <div class="flex p-6" data-controller="calendar">
    <div class="w-2/3">
      <div data-calendar-target="calendar"></div>
    </div>
    <div class="w-1/3 px-6">
      <h3 class="text-xl font-bold">Events</h3>

      <%= turbo_frame_tag "new_event", src: new_event_path %>

      <hr class="my-6">

      <ul id="events">
        <% @events.each do |event| %>
          <%= render event %>
        <% end %>
      </div>
    </div>
  </div>
<% end %>
```

4. The `new_event` frame's `src` points at `events#new`, which renders the same-named turbo frame wrapping the create form — this is the standard lazy-loaded turbo frame form pattern.

**`app/views/events/new.html.erb`**
```erb
<%= turbo_frame_tag "new_event" do %>
  <%= render "form", event: @event %>
<% end %>
```

**`app/views/events/_form.html.erb`**
```erb
<%= form_with model: event, class: "space-y-6" do |f| %>
  <div>
    <%= f.label :title, class: "block text-sm font-medium leading-6 text-gray-900" %>
    <div class="mt-2">
      <%= f.text_field :title, class: "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6", placeholder: "Dinner with friends" %>
    </div>
  </div>
  
  <div>
    <%= f.label :starting_at, class: "block text-sm font-medium leading-6 text-gray-900" %>
    <div class="mt-2">
      <%= f.date_field :starting_at, class: "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6" %>
    </div>
  </div>

  <%= f.submit "Create event", class: "bg-indigo-600 rounded text-white hover:bg-indigo-700 p-2 w-full" %>
<% end %>
```

5. This is the crux of the trick: on a successful create, the Turbo Stream response re-renders the (now blank) form into the `new_event` frame and appends the new event's `_event` partial into the `events` list. Because that partial carries `data-calendar-target="event"`, Stimulus fires `eventTargetConnected` the moment it lands in the DOM, and the calendar controller (already alive on the page) picks it up and calls `addEvent` — no explicit event listener or manual DOM query is needed to bridge the Turbo Stream append into the FullCalendar instance.

**`app/views/events/create.turbo_stream.erb`**
```erb
<%= turbo_stream.update "new_event", partial: "events/form", locals: { event: Event.new } %>
<%= turbo_stream.append "events", partial: "events/event", locals: { event: @event } %>
```

**`app/views/events/_event.html.erb`**
```erb
<li class="relative flex space-x-6 py-6 xl:static"
  data-calendar-target="event"
  data-id="<%= event.id %>"
  data-title="<%= event.title %>"
  data-starting-at="<%= event.starting_at %>">
  <div class="flex-auto">
    <h3 class="pr-10 font-semibold text-gray-900 xl:pr-0"><%= event.title %></h3>
    <dl class="mt-2 flex flex-col text-gray-500 xl:flex-row">
      <div class="flex items-start space-x-3">
        <dt class="mt-0.5">
          <span class="sr-only">Date</span>
          <svg class="h-5 w-5 text-gray-400" viewBox="0 0 20 20" fill="currentColor" aria-hidden="true">
            <path fill-rule="evenodd" d="M5.75 2a.75.75 0 01.75.75V4h7V2.75a.75.75 0 011.5 0V4h.25A2.75 2.75 0 0118 6.75v8.5A2.75 2.75 0 0115.25 18H4.75A2.75 2.75 0 012 15.25v-8.5A2.75 2.75 0 014.75 4H5V2.75A.75.75 0 015.75 2zm-1 5.5c-.69 0-1.25.56-1.25 1.25v6.5c0 .69.56 1.25 1.25 1.25h10.5c.69 0 1.25-.56 1.25-1.25v-6.5c0-.69-.56-1.25-1.25-1.25H4.75z" clip-rule="evenodd" />
          </svg>
        </dt>
        <dd><%= event.starting_at.strftime("%B #{event.starting_at.day.ordinalize}, %Y") %></dd>
      </div>
    </dl>
  </div>
</li>
```

6. The calendar demo is wired into the kitchensink page behind a lazily-loaded turbo frame, and `events` gets a scoped resources route. The only JS dependency is the FullCalendar library (`@fullcalendar/core` + `@fullcalendar/daygrid`).

**`app/views/pages/kitchensink.html.erb`** (addition)
```erb
<%= render "shared/divider", title: "Day 27/30 - Calendar" %>

<div class="mx-auto my-20 flex items-start justify-center min-h-[500px]">
  <%= turbo_frame_tag "calendar_callbacks", src: events_path, class: "w-full" %>
</div>
```

**`config/routes.rb`** (addition)
```ruby
resources :events, only: %i[index new create]
```

**Why it matters / when to use:** Use Stimulus target-connected/disconnected callbacks whenever a third-party JS widget (a calendar, a chart, a map, a rich list component) needs to be told about DOM nodes that Turbo Streams add or remove — it's a much cleaner integration point than hand-rolled MutationObservers or manually re-initializing the widget after every stream update.

`Pattern:` turbo-frames, lazy-frames, turbo-streams, stimulus, stimulus-targets, stimulus-target-callbacks, forms, third-party-js

---

## Day 28 — Custom Turbo confirm dialog

**Source:** https://x.com/itsameandrea/status/1637197232930955265  ·  **Date:** 2023-03-18  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/5cf72301154c9e2797f6ea26a5f87891a6ec6332

By default, `data-turbo-confirm` shows the browser's plain `window.confirm()` dialog before a destructive request fires. Turbo lets you replace that entirely with `Turbo.setConfirmMethod`, which must return a Promise that resolves truthy to proceed. This tip turns that hook into a reusable `turbo-confirm` Stimulus controller that drives a native `<dialog>` element: it fills in the title/body/button text (with sane defaults, overridable per-form via data attributes), shows the dialog modally, and resolves the promise based on which button the user clicked — giving every destructive action in the app a styled, customizable confirmation modal with no page-specific JS.

### How it works

1. Any `<form>` (typically generated by `button_to ..., method: :delete`) can opt into the dialog just by setting `data-turbo-confirm`. Additional `data-confirm-title`, `data-confirm-body`, `data-confirm-btn-text`, and `data-cancel-btn-text` attributes on the same element override the controller's defaults for that specific action.

**`app/views/characters/index.html.erb`** (excerpt)
```erb
<%= button_to character_path(character),
  method: :delete,
  form: {
    data: {
      turbo_confirm: "true",
      confirm_body: "The world may implode if you continue."
    }
  } do %>
  <svg xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke-width="1.5" stroke="currentColor" class="w-6 h-6">
    <path stroke-linecap="round" stroke-linejoin="round" d="M14.74 9l-.346 9m-4.788 0L9.26 9m9.968-3.21c.342.052.682.107 1.022.166m-1.022-.165L18.16 19.673a2.25 2.25 0 01-2.244 2.077H8.084a2.25 2.25 0 01-2.244-2.077L4.772 5.79m14.456 0a48.108 48.108 0 00-3.478-.397m-12 .562c.34-.059.68-.114 1.022-.165m0 0a48.11 48.11 0 013.478-.397m7.5 0v-.916c0-1.18-.91-2.164-2.09-2.201a51.964 51.964 0 00-3.32 0c-1.18.037-2.09 1.022-2.09 2.201v.916m7.5 0a48.667 48.667 0 00-7.5 0" />
  </svg>
<% end %>
```

2. `TurboConfirmController` declares default `title`/`body`/`confirmButtonText`/`cancelButtonText` Stimulus values, plus targets for the dialog and its title/body/button elements. On `connect()` it calls `Turbo.setConfirmMethod`, installing itself as the app-wide confirm handler.

**`app/javascript/controllers/turbo_confirm_controller.js`**
```js
import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="turbo-confirm"
export default class extends Controller {
  static targets = ["dialog", "title", "body", "confirmButton", "cancelButton"]
  static values = {
    title: {
      type: String,
      default: "Are you sure?"
    },
    body: {
      type: String,
      default: "This action can't be undone"
    },
    confirmButtonText: {
      type: String,
      default: "Yes, I'm sure"
    },
    cancelButtonText: {
      type: String,
      default: "Cancel"
    }
  }

  connect() {
    this.setupDialog()
  }

  setupDialog() {
    Turbo.setConfirmMethod((_, element) => {    
      let {
        confirmTitle: titleText,
        confirmBody: bodyText,
        confirmBtnText,
        cancelBtnText
      } = element.dataset
    
      this.titleTarget.innerText = titleText || this.titleValue
      this.bodyTarget.innerText = bodyText || this.bodyValue
      this.confirmButtonTarget.innerText = confirmBtnText || this.confirmButtonTextValue
      this.cancelButtonTarget.innerText = cancelBtnText || this.cancelButtonTextValue
    
      this.dialogTarget.classList.remove('hidden')
    
      this.dialogTarget.showModal()
    
      return new Promise((resolve, reject) => {
        this.dialogTarget.addEventListener("close", () => {
          this.dialogTarget.classList.add('hidden')
          resolve(this.dialogTarget.returnValue === "confirm")
        }, { once: true })
      })
    })
  }
}
```

**`app/javascript/controllers/index.js`** (addition)
```js
import TurboConfirmController from "./turbo_confirm_controller"
application.register("turbo-confirm", TurboConfirmController)
```

3. The dialog markup is a single shared partial rendered once in the layout. It's a `<dialog>` (native modal semantics — `showModal()`, backdrop, `Esc`-to-close) wrapped in a `method="dialog"` form; each button's `value` (`"confirm"` / `"cancel"`) becomes `dialog.returnValue` when clicked, which is exactly what the controller reads to resolve the promise.

**`app/views/shared/_turbo_destroy_dialog.html.erb`**
```erb
<dialog data-turbo-confirm-target="dialog" class="hidden">
  <div data-form="destroy" class="animated fadeIn fixed inset-0 overflow-y-auto flex items-center justify-center">
    <!-- Modal Inner Container -->
    <form method="dialog" class="max-h-screen w-full max-w-lg relative flex justify-center">
      <!-- Modal Card -->
      <div class="inline-block align-bottom bg-white rounded-lg px-4 pt-5 pb-4 text-left overflow-hidden shadow-xl transform transition-all sm:my-8 sm:align-middle sm:max-w-lg sm:w-full sm:p-6">
        <div class="sm:flex sm:items-start">
          <div class="mx-auto flex-shrink-0 flex items-center justify-center h-12 w-12 rounded-full bg-red-100 sm:mx-0 sm:h-10 sm:w-10">
            <!-- Heroicon name: outline/exclamation -->
            <svg class="h-6 w-6 text-red-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24" stroke="currentColor" aria-hidden="true">
              <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
            </svg>
          </div>
          <div class="mt-3 text-center sm:mt-0 sm:ml-4 sm:text-left">
            <h3 class="text-lg leading-6 font-medium text-gray-900" data-turbo-confirm-target="title">
            </h3>
            <div class="mt-2">
              <p class="text-sm text-gray-500" data-turbo-confirm-target="body">
              </p>
            </div>
          </div>
        </div>
        <div class="mt-5 sm:mt-4 sm:flex sm:flex-row-reverse">
          <button data-turbo-confirm-target="confirmButton" value="confirm" class="w-full inline-flex justify-center rounded-md border border-transparent shadow-sm px-4 py-2 bg-red-600 text-base font-medium text-white hover:bg-red-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-red-500 sm:ml-3 sm:w-auto sm:text-sm">
          </button>
          <button data-turbo-confirm-target="cancelButton" value="cancel" class="mt-3 w-full inline-flex justify-center rounded-md border border-gray-300 shadow-sm px-4 py-2 bg-white text-base font-medium text-gray-700 hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-indigo-500 sm:mt-0 sm:w-auto sm:text-sm">
          </button>
        </div>
      </div>
    </form>
  </div>
</dialog>
```

4. The layout instantiates `turbo-confirm` alongside the existing `command-palette` controller on `<body>`, and renders the shared dialog partial once so it's available app-wide.

**`app/views/layouts/application.html.erb`** (relevant excerpt)
```erb
<body data-controller="command-palette turbo-confirm" data-action="keydown.ctrl+a->command-palette#toggle keydown.esc->command-palette#close">
  <%= render 'shared/flash' %>
  
  <%= yield %>

  <%= render 'shared/command_palette' %>
  <%= render "shared/turbo_destroy_dialog" %>
  
  <%= turbo_frame_tag "modal" %>
  <%= turbo_frame_tag "flash" %>
</body>
```

5. This whole controller replaces an earlier, non-Stimulus version of the same idea that lived directly in `application.js` as a bare `Turbo.setConfirmMethod` call querying `document.getElementById("turbo_confirm")` — that inline version is removed in this commit in favor of the reusable controller above.

**Why it matters / when to use:** Drop this controller into any Hotwire app as boilerplate for destructive actions (deletes, irreversible state changes) — it upgrades every `data-turbo-confirm` form from a jarring native `confirm()` into a branded, per-action-customizable modal, with the Promise-based `Turbo.setConfirmMethod` contract doing all the async heavy lifting.

`Pattern:` stimulus, stimulus-values, stimulus-targets, turbo-confirm, modals, forms

---

## Day 29 — File upload with Uppy

**Source:** _thread not linked in container (see Gaps)_  ·  **Date:** 2023-03-19  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/75d7d6c

This commit wires the [Uppy](https://uppy.io) JS upload widget to Rails Active Storage direct uploads via a `uppy` Stimulus controller. Uppy handles the drag-and-drop UI, progress bar, and the direct-to-storage upload itself (through the `@excid3/uppy-activestorage-upload` plugin, which talks to Rails' `rails_direct_uploads_path` endpoint); on success, the controller clones `<template>` elements to inject an image preview and a hidden form field carrying the resulting blob's signed ID, so the surrounding Rails form submits the upload like any other attached-file parameter without a full page reload.

### How it works

1. `Pet` is a plain ActiveRecord model with a single attached photo via Active Storage, and `PetsController` is a standard `new`/`create`/`index` controller — `create` just saves the record (photo included, since the hidden field holds its signed ID) and redirects.

**`app/models/pet.rb`**
```ruby
class Pet < ApplicationRecord
  has_one_attached :photo
end
```

**`app/controllers/pets_controller.rb`**
```ruby
class PetsController < ApplicationController
  def new
    @pet = Pet.new
  end

  def create
    @pet = Pet.new(pet_params)

    if @pet.save
      redirect_to pets_path
    else
      render :new
    end
  end

  def index
    @pets = Pet.all
  end
  
  private

  def pet_params
    params.require(:pet).permit(:name, :photo)
  end
end
```

2. `UppyController` targets a `dropzone`, a `progressBar`, an `uploadedFiles` container, and two `<template>`s (`preview`, `input`). It takes a `directUploadUrl` value pointing at Rails' Active Storage direct-upload endpoint. On `connect()` it builds an Uppy instance with the `DragDrop` UI plugin, the `ActiveStorageUpload` plugin (which performs the actual direct upload against Rails), and a `ProgressBar` plugin, then listens for `upload-success`.

**`app/javascript/controllers/uppy_controller.js`**
```js
import { Controller } from "@hotwired/stimulus"
import Uppy from '@uppy/core'
import DragDrop from '@uppy/drag-drop'
import ProgressBar from '@uppy/progress-bar'
import ActiveStorageUpload from '@excid3/uppy-activestorage-upload'

// Connects to data-controller="uppy"
export default class extends Controller {
  static targets = ["dropzone", "progressBar", "uploadedFiles", "preview", "input"]
  static values = { directUploadUrl: String }

  connect() {
    this.setupUppy()
  }

  setupUppy() {
    this.uppyInstance = new Uppy({ debug: true, autoProceed: true })

    this.uppyInstance
      .use(DragDrop, { target: this.dropzoneTarget })
      .use(ActiveStorageUpload, { directUploadUrl: this.directUploadUrlValue })
      .use(ProgressBar, { target: this.progressBarTarget, hideAfterFinish: false })
      .on('upload-success', this.onUploadSuccess.bind(this))
  }

  onUploadSuccess(file, response) {
    const url = response.uploadURL
    const fileName = file.name

    const preview = this.previewTarget.content.cloneNode(true)
    const input = this.inputTarget.content.cloneNode(true)

    const img = preview.querySelector('img')
    img.src = `/rails/active_storage/blobs/redirect/${response.signed_id}/${response.filename}`

    const field = input.querySelector('input')
    field.value = response.signed_id

    this.uploadedFilesTarget.appendChild(preview)
    this.uploadedFilesTarget.appendChild(input)
  }
}
```

**`app/javascript/controllers/index.js`** (addition)
```js
import UppyController from "./uppy_controller"
application.register("uppy", UppyController)
```

3. `onUploadSuccess` is the payoff: since `autoProceed: true` is set, Uppy starts uploading as soon as a file is dropped, without waiting for a form submit button. Once the direct upload to Active Storage finishes, Uppy hands back a `signed_id` for the resulting blob — the controller clones the `preview` template to show the image immediately, and clones the `input` template to inject a hidden field pre-filled with that `signed_id`. Because the hidden field's name matches `pet[photo]`, submitting the surrounding form attaches the already-uploaded blob to the `Pet` record without re-uploading the file.

4. `pets/new.html.erb` wires the controller onto a wrapper div around the file-upload portion of the form, passing the direct-upload URL as a Stimulus value, and declares the dropzone/progress-bar/preview/input targets referenced above.

**`app/views/pets/new.html.erb`**
```erb
<%= turbo_frame_tag "pets" do %>
  <%= form_with model: @pet, class: "space-y-6 p-10" do |f| %>
    <div>
      <%= f.label :name, class: "block text-sm font-medium leading-6 text-gray-900" %>
      <div class="mt-2">
        <%= f.text_field :name, class: "block w-full rounded-md border-0 py-1.5 text-gray-900 shadow-sm ring-1 ring-inset ring-gray-300 placeholder:text-gray-400 focus:ring-2 focus:ring-inset focus:ring-indigo-600 sm:text-sm sm:leading-6", placeholder: "Mr. Pepperoni" %>
      </div>
    </div>
    
    <div
      data-controller="uppy"
      data-uppy-direct-upload-url-value="<%= rails_direct_uploads_path %>">
      <%= f.label :photo, class: "block text-sm font-medium leading-6 text-gray-900 sm:pt-1.5" %>
      <div class="mt-2 sm:col-span-2 sm:mt-0">
        <div data-uppy-target="dropzone">
          <div data-uppy-target="progressBar"></div>
        </div>

        <div class="mt-6" data-uppy-target="uploadedFiles">
          <template data-uppy-target="preview">
            <img src="#" class="w-20 h-20 object-cover rounded">
          </template>

          <template data-uppy-target="input">
            <%= f.hidden_field :photo %>
          </template>
        </div>
      </div>
    </div>

    <%= f.submit "Add Pet", class: "bg-indigo-600 rounded text-white hover:bg-indigo-700 p-2 w-full" %>
  <% end %>
<% end %>
```

5. `pets/index.html.erb` lists saved pets in a table, rendering each attached photo with the standard `image_tag pet.photo` helper.

**`app/views/pets/index.html.erb`**
```erb
<%= turbo_frame_tag "pets", class: "w-full" do %>
  <div class="px-4 sm:px-6 lg:px-8 py-8">
    <div class="sm:flex sm:items-center">
      <div class="flex w-full justify-between">
        <h1 class="text-base font-semibold leading-6 text-gray-900">Cute pets 🐶</h1>
        <%= link_to "Add Pet", new_pet_path, class: "bg-indigo-600 text-white py-2 px-3 rounded" %>
      </div>
    </div>

    <div class="flow-root">
      <div class="-my-2 -mx-4 overflow-x-auto sm:-mx-6 lg:-mx-8">
        <div class="inline-block min-w-full py-2 align-middle sm:px-6 lg:px-8">
          <table class="min-w-full divide-y divide-gray-300">
            <thead>
              <tr>
                <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Photo</th>
                <th scope="col" class="py-3.5 pl-4 pr-3 text-left text-sm font-semibold text-gray-900 sm:pl-0">Name</th>
              </tr>
            </thead>
            <tbody class="divide-y divide-gray-200">
              <% @pets.each do |pet| %>
                <tr>
                  <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                    <%= image_tag pet.photo, class: "inline-block h-14 w-14 rounded-md object-cover" %>
                  </td>
                  <td class="whitespace-nowrap py-4 pl-4 pr-3 text-sm font-medium text-gray-900 sm:pl-0">
                    <%= pet.name %>
                  </td>
                </tr>
              <% end %>
            </tbody>
          </table>
        </div>
      </div>
    </div>
  </div>
<% end %>
```

**`app/views/pets/show.html.erb`**
```erb
<%= @pet.name %>

<%= image_tag @pet.photo, class: "h-20 w-20 object-cover" %>
```

6. `pets` gets a scoped resources route, and the demo page links to it behind a lazy-loaded turbo frame like the other days. The layout also loads Uppy's vendored stylesheet from a CDN (`https://cdnjs.cloudflare.com/ajax/libs/uppy/3.6.1/uppy.min.css`), which isn't reproduced here.

**`config/routes.rb`** (addition)
```ruby
resources :pets, only: %i[new create index]
```

**`app/views/pages/kitchensink.html.erb`** (addition)
```erb
<%= render "shared/divider", title: "Day 29/30 - File upload with Uppy" %>

<div class="mx-auto my-20 flex items-start justify-center min-h-[500px]">
  <%= turbo_frame_tag "pets", src: pets_path, class: "w-full" %>
</div>
```

**Why it matters / when to use:** Reach for this pattern when a form needs a richer upload UX (drag-and-drop, progress, previews) than a bare Rails file field gives you, but you still want the upload itself to go straight to storage (Active Storage direct upload) rather than through your Rails process — the `<template>`-cloning trick is a clean, dependency-light way to bridge a JS widget's async result back into a normal server-rendered form.

`Pattern:` stimulus, stimulus-values, stimulus-targets, forms, file-upload, third-party-js

---

## Day 30 — Custom Turbo Stream actions

**Source:** https://x.com/itsameandrea/status/1638303138267426818  ·  **Date:** 2023-03-21  ·  **Code:** https://github.com/itsameandrea/thirty_days_of_hotwire/commit/c18475b2983b12cd662a6ee61bb5389eb4b4447a

Turbo Streams ship with a fixed set of built-in actions (`append`, `replace`, `remove`, etc.), but Turbo also lets you register your own by adding a function to `StreamActions`. This tip defines a custom `analytics` action that fires a client-side analytics call (`window.beam()`, from Beam Analytics) whenever a matching `<turbo-stream action="analytics">` element is processed — plus a Ruby helper so `analytics` can be called from `.turbo_stream.erb` templates exactly like a built-in action. The result: server-side business logic can trigger client-side analytics tracking through the same Turbo Stream response it already sends, with no dedicated JS event or extra request.

### How it works

1. `StreamActions.analytics` is assigned a function that reads an `event` attribute off the custom element (`this` inside a stream action refers to the `<turbo-stream>` element) and calls `window.beam()` with it, matching the Beam Analytics tracking API. This replaces the file's previous contents — the day 28 `Turbo.setConfirmMethod` call has moved into its own `turbo_confirm_controller.js` (see Day 28) and is no longer inline here.

**`app/javascript/application.js`**
```js
import "@hotwired/turbo-rails"
import "trix"
import "@rails/actiontext"
import "./controllers"

import { StreamActions } from "@hotwired/turbo"

StreamActions.analytics = function() {
  const event = this.getAttribute("event")
  window.beam(`/custom-events/${event}`)
}
```

2. To make `analytics` callable from `.turbo_stream.erb` views the same way `turbo_stream.append` or `turbo_stream.update` are, a helper module prepends itself onto Turbo's `TagBuilder`, adding an `analytics(event)` method that renders a `<turbo-stream action="analytics" event="...">` tag via `turbo_stream_action_tag`.

**`app/helpers/turbo_streams/analytics_helper.rb`**
```ruby
module TurboStreams::AnalyticsHelper
  def analytics(event)
    turbo_stream_action_tag :analytics, event: event
  end
end
Turbo::Streams::TagBuilder.prepend(TurboStreams::AnalyticsHelper)
```

3. `PagesController#track_event` is a minimal action standing in for "some business logic event that we want to track" — it does no real work, just responds with a Turbo Stream template.

**`app/controllers/pages_controller.rb`** (addition)
```ruby
def track_event
  # some business logic event
  # that we want to track
  
  respond_to do |format|
    format.turbo_stream
  end
end
```

4. The Turbo Stream template calls the new `analytics` helper just like any built-in stream helper, tracking a `"user_sign_up"` event.

**`app/views/pages/track_event.turbo_stream.erb`**
```erb
<%= turbo_stream.analytics "user_sign_up" %>

```

5. A button on the demo page posts to the new route, and Beam Analytics' tracking script is loaded (with its token pulled from Rails credentials) so `window.beam()` exists on the page.

**`app/views/pages/kitchensink.html.erb`** (addition)
```erb
<%= render "shared/divider", title: "Day 30/30 - Custom turbo stream actions" %>

<div class="mx-auto my-20 flex items-start justify-center">
  <%= button_to "Track an Event", track_event_path, method: :post, class: "bg-indigo-600 text-white p-3 rounded-lg" %>
</div>
```

**`app/views/layouts/application.html.erb`** (addition)
```erb
<script src="https://beamanalytics.b-cdn.net/beam.min.js" data-token="<%= Rails.application.credentials.dig(:beam, :token) %>" async></script>
```

**`config/routes.rb`** (addition)
```ruby
post 'track_event', to: 'pages#track_event'
```

**Why it matters / when to use:** Custom Turbo Stream actions are the general escape hatch whenever a stream response needs to do something other than mutate the DOM — analytics pings, toast notifications, triggering a download, playing a sound. For a bigger library of ready-made custom actions (scroll-to, redirect, console log, etc.), the tip points at Marco Roth's [`turbo_power-rails`](https://github.com/marcoroth/turbo_power-rails) gem.

`Pattern:` turbo-streams, custom-stream-actions, third-party-js, notifications

---

---

## Index

| Day | Title | Pattern |
| --- | --- | --- |
| 1 | (Nearly) JS-less multiple select input | turbo-frames, lazy-frames, stimulus, autosubmit, forms, search-filter |
| 2 | Realtime online users with Turbo broadcasts | turbo-streams, broadcasts, actioncable, turbo-frames, lazy-frames |
| 3 | Animating Turbo Stream appends and removals | turbo-streams, stimulus, animation |
| 4 | JS-less modals with Turbo Frames | turbo-frames, modals |
| 5 | Infinite scroll in under 5 minutes | turbo-frames, lazy-frames, turbo-streams, pagination |
| 6 | Dynamic nested forms | nested-forms, turbo-streams, turbo-frames, lazy-frames, stimulus, stimulus-values, stimulus-targets, forms |
| 7 | (Almost) JS-less table filters | search-filter, autosubmit, turbo-frames, stimulus, third-party-js, forms |
| 8 | Ridiculously simple real-time chat | broadcasts, actioncable, turbo-streams, stimulus, forms |
| 9 | Real-time tic tac toe | broadcasts, actioncable, turbo-streams, turbo-frames, lazy-frames |
| 10 | Multi-step forms | multi-step-forms, forms, validation, turbo-frames, lazy-frames |
| 11 | Flash messages without a page reload | turbo-streams, turbo-frames, flash, stimulus |
| 12 | Command palette with a keyboard shortcut | stimulus, hotkeys, stimulus-targets, turbo-frames, autosubmit, search-filter, modals |
| 13 | Quick and easy reactive maps (Mapbox) | stimulus, stimulus-values, turbo-frames, third-party-js, forms |
| 14 | Hotwire with ViewComponents | view-components, turbo-streams, turbo-frames, autosubmit, animation |
| 15 | ChatGPT + Hotwire (long-running job, live result) | turbo-frames, turbo-streams, broadcasts, actioncable, forms, ai |
| 16 | Tabbed content with Turbo Frames | turbo-frames, lazy-frames |
| 17 | Twitter-style preview / undo / send | stimulus, stimulus-targets, stimulus-values, turbo-frames, turbo-permanent, forms |
| 18 | Markdown editor with live preview | turbo-frames, autosubmit, forms, stimulus |
| 19 | Pulse loading state for lazy Turbo Frames | turbo-frames, lazy-frames, animation |
| 20 | Dynamic (dependent) select fields | turbo-frames, autosubmit, forms, turbo-permanent, stimulus |
| 21 | Searchable dropdown input | turbo-streams, stimulus, stimulus-values, search-filter, forms, third-party-js |
| 22 | Kanban board with drag and drop | drag-drop, stimulus, stimulus-targets, stimulus-values, turbo-streams, turbo-frames, flash, third-party-js |
| 23 | Real-time notifications with the noticed gem | notifications, broadcasts, actioncable, turbo-streams, turbo-frames, third-party-js |
| 24 | Gmail-style bulk select | turbo-frames, forms, pagination, search-filter |
| 25 | Reddit-style lazy-loaded nested comments | turbo-frames, lazy-frames, turbo-streams, turbo-permanent, forms, nested-forms |
| 26 | Scroll animations with Stimulus + IntersectionObserver | stimulus, stimulus-values, stimulus-targets, stimulus-classes, animation |
| 27 | FullCalendar with Stimulus target callbacks | turbo-frames, lazy-frames, turbo-streams, stimulus, stimulus-targets, stimulus-target-callbacks, forms, third-party-js |
| 28 | Custom Turbo confirm dialog | stimulus, stimulus-values, stimulus-targets, turbo-confirm, modals, forms |
| 29 | File upload with Uppy | stimulus, stimulus-values, stimulus-targets, forms, file-upload, third-party-js |
| 30 | Custom Turbo Stream actions | turbo-streams, custom-stream-actions, third-party-js, notifications |

### Pattern frequency

| Pattern | Days |
| --- | --- |
| turbo-frames | 1, 2, 4, 5, 6, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 22, 23, 24, 25, 27 |
| lazy-frames | 1, 2, 5, 6, 9, 10, 16, 19, 25, 27 |
| turbo-streams | 2, 3, 5, 6, 8, 9, 11, 14, 15, 21, 22, 23, 25, 27, 30 |
| stimulus | 1, 3, 6, 7, 8, 11, 12, 13, 17, 18, 20, 21, 22, 26, 27, 28, 29 |
| broadcasts / actioncable | 2, 8, 9, 15, 23 |
| forms | 1, 6, 7, 8, 10, 13, 15, 17, 18, 20, 21, 24, 25, 27, 28, 29 |
| autosubmit (the Day 1 controller) | 1, 7, 12, 14, 18, 20 |
| third-party-js | 7, 13, 21, 22, 23, 27, 29, 30 |
| turbo-permanent | 17, 20, 25 |
| animation | 3, 14, 19, 26 |
| search-filter | 1, 7, 12, 21, 24 |
| modals | 4, 12, 28 |

---

## Gaps

**Threads that could not be retrieved (2 of 30):**

1. **Day 16 — Tabbed content.** The container thread contains only 28 `t.co` links, and Day 16
   is not one of them. Andrea posted it around 2023-03-06 (the repo commit `cd3d8b9` is dated
   that day) but the tweet id could not be recovered: the `twitter` CLI's search endpoint
   returns HTTP 404 for every query, and web search surfaced nothing. **The Day 16 entry above
   is reconstructed entirely from the repo commit** — the code is authoritative, but the prose
   framing is mine, not Andrea's, and any commentary he gave in the thread is lost.

2. **Day 29 — File upload with Uppy.** Same situation. Repo commit `75d7d6c`, dated 2023-03-19.
   Reconstructed from code only.

**Numbering irregularities in the source material:**

- Andrea's own tip numbering skips 16 and 29, and *two* threads are labelled "22/30"
  (2023-03-12 Kanban board and 2023-03-13 notifications). He corrected the second one to
  Day 23 in a follow-up reply. This file uses the repo's commit numbering, which is
  consistent and matches the tweets everywhere else.
- On Day 21 Andrea noted that only the first two tweets of his thread actually posted
  overnight; he backfilled the rest the next morning. All of them are captured here.

**Sources deliberately not transcribed:**

- **Demo videos.** Every day opens with a screen recording of the finished result. These are
  not transcribed; the mp4 URLs are in the raw capture if a visual reference is wanted.
- **Code screenshots.** Transcribed from the companion repo instead, which is byte-exact and
  includes context the screenshots cropped. The one screenshot with content *not* in the repo
  — the Turbo docs excerpt on `turbo:before-frame-render` in Day 4 — was read and transcribed
  directly.
- **Vendored assets.** Day 26's diff is dominated by a vendored `animate.css` and static
  landing-page markup; Day 29's by Uppy's bundled assets. Only the hand-written app code is
  reproduced, with the dependency noted in prose.

**Minor discrepancies between the tweets and the repo:**

- Day 9's tweet links to PR #9 rather than a commit; the merged commit is `0e37fb6`.
- Day 13's tweet links commit `d2f5be5` on a feature branch; the mainline merge is `b5f7c61`
  (identical code).
- Days 1 and 2 each got a follow-up refactor commit (`47de131`, `0c46ac8`) after the thread
  was published, moving the widget into its own Turbo Frame. The final state is presented and
  the difference is called out inline.
- Day 23's `Notification#broadcast_to_recipient` in commit `7554db8` is missing a comma and
  would not parse; Andrea fixed it in the Day 24 commit. The original is transcribed as-is
  with a note.

**No blog/newsletter posts to fetch.** Across all 28 retrieved threads the only outbound
article links are to other people's material: Jason Swett's multi-step forms post (Day 10,
summarised inline), Chris Oliver's dynamic-select video (Day 20), Marco Roth's `turbo_power`
gem (Day 30), and a CodePen for the tic-tac-toe markup (Day 9). Andrea's own links all point
at the companion repo or at his side project MailClipper.
