# frozen_string_literal: true

module Crosswire
  # Included into Crosswire::Builder (lib/crosswire/builder.rb), not mixed into views
  # directly. Reach these methods through the facade helper: `cw.combobox`,
  # `cw.combobox_for`, `cw.combobox_attrs` — or the canonical `crosswire.` in place of
  # `cw.`.
  module ComboboxHelper
    # Batteries-included form — renders the shipped partial.
    #
    #   <%= cw.combobox id: "state", name: "record[state]", label: "State",
    #         value: "CA", display: "California",
    #         options: [{ value: "CA", display: "California" }, { value: "NY", display: "New York" }] %>
    #
    # `options:` is an ordered array of `{ value:, display: }` (mirrors `cw.tabs`'
    # `{ id:, label: }`) — left empty for `filter: "remote"`, where the listbox's
    # contents arrive from the server on demand instead. See
    # `Crosswire::Presenters::Combobox`'s Rule 0 before reaching for this at all — a
    # plain `<select>` or a `<datalist>` covers most "pick one" cases with zero
    # JavaScript.
    def combobox(id:, name:, label: nil, options: [], **presenter_options)
      presenter = Crosswire::Presenters::Combobox.new(id: id, name: name, label: label, **presenter_options)

      render("crosswire/combobox", combobox: presenter, label: label, options: options)
    end

    # Compose-it-yourself form — yields the presenter, renders no markup of ours.
    #
    #   <%= cw.combobox_for id: "state", name: "record[state]" do |c| %>
    #     <div <%= cw_attrs(c.root_attrs) %>>
    #       <label <%= cw_attrs(c.label_attrs) %>>State</label>
    #       <input <%= cw_attrs(c.input_attrs) %>>
    #       <input <%= cw_attrs(c.field_attrs) %>>
    #       <ul <%= cw_attrs(c.listbox_attrs) %>>
    #         <li <%= cw_attrs(c.option_attrs(value: "CA", display: "California")) %>>California</li>
    #       </ul>
    #     </div>
    #   <% end %>
    def combobox_for(id:, name:, **presenter_options, &block)
      capture(Crosswire::Presenters::Combobox.new(id: id, name: name, **presenter_options), &block)
    end

    # Returns the merged root attribute hash — a plain Hash, ready for `cw_attrs` or
    # `tag.div(**...)`. Renders and escapes nothing itself; that is `cw_attrs`' job.
    #
    #   <div <%= cw_attrs(cw.combobox_attrs(id: "state", name: "record[state]")) %>>…</div>
    def combobox_attrs(id:, name:, **presenter_options)
      Crosswire::Presenters::Combobox.new(id: id, name: name, **presenter_options).root_attrs
    end
  end
end
