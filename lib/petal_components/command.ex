defmodule PetalComponents.Command do
  @moduledoc """
  A command palette — the ⌘K menu. Type to filter, arrow keys to move,
  Enter to run. Items are real links and buttons, so `navigate`, `patch`
  and any `phx-*` binding work exactly as they do everywhere else in
  LiveView.

  Filtering happens client-side in the `PetalCommand` hook (zero
  dependencies), so keystrokes never wait on the server. Items are hidden,
  never reordered — the server owns DOM order, which keeps the component
  safe under LiveView patches.

  Two shells:

    * `command/1` — an inline palette panel (for docs pages, sidebars,
      pickers).
    * `command_dialog/1` — the palette in a native `<dialog>`, opened with
      ⌘K / Ctrl+K (configurable) or `JS.dispatch("pc:command-open")`. The
      native element gives the top layer, focus trap, backdrop and Escape
      for free.

  The markup follows the WAI-ARIA combobox pattern: the input carries
  `role="combobox"` and `aria-activedescendant`, the list is a `listbox`,
  items are `option`s. Keyboard focus never leaves the input; selection is
  a virtual highlight.
  """
  use Phoenix.Component

  alias Phoenix.LiveView.JS
  import PetalComponents.Icon

  attr :id, :string, required: true, doc: "unique id; the PetalCommand hook mounts here"

  attr :loop, :boolean,
    default: false,
    doc: "arrow keys wrap from the last item to the first and back"

  attr :class, :any, default: nil, doc: "extra classes for the palette panel"
  attr :rest, :global

  slot :inner_block, required: true

  @doc """
  The inline command palette.

      <.command id="file-menu">
        <.command_input placeholder="Type a command or search..." />
        <.command_list>
          <.command_empty>No results found.</.command_empty>
          <.command_group heading="Suggestions">
            <.command_item navigate={~p"/calendar"}>
              <.icon name="hero-calendar" /> Calendar
            </.command_item>
            <.command_item phx-click="open_emoji">
              <.icon name="hero-face-smile" /> Search emoji
              <.command_shortcut>⌘E</.command_shortcut>
            </.command_item>
          </.command_group>
        </.command_list>
      </.command>
  """
  def command(assigns) do
    ~H"""
    <div
      id={@id}
      class={["pc-command", @class]}
      phx-hook="PetalCommand"
      data-loop={@loop && "true"}
      {@rest}
    >
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :id, :string,
    required: true,
    doc: "unique id for the dialog; open it with ⌘K or open_command/1"

  attr :shortcut, :string,
    default: "k",
    doc:
      "the key bound with Cmd (mac) / Ctrl to toggle the dialog. Set to nil to disable the global binding"

  attr :loop, :boolean, default: false, doc: "arrow keys wrap around the list"

  attr :reset_on_close, :boolean,
    default: true,
    doc: "clear the query (and restore all items) when the dialog closes"

  attr :class, :any, default: nil, doc: "extra classes for the palette panel inside the dialog"
  attr :rest, :global

  slot :inner_block, required: true

  @doc """
  The command palette in a native `<dialog>` — the classic ⌘K experience.

      <.command_dialog id="cmdk">
        <.command_input placeholder="Type a command or search..." />
        <.command_list>
          <.command_empty>No results found.</.command_empty>
          ...
        </.command_list>
      </.command_dialog>

  Open it from any element:

      <.button phx-click={PetalComponents.Command.open_command("cmdk")}>
        Search <.command_shortcut>⌘K</.command_shortcut>
      </.button>

  The dialog closes on Escape, backdrop click, or after an item runs
  (add `data-keep-open` to an item to opt out).
  """
  def command_dialog(assigns) do
    ~H"""
    <dialog
      id={@id}
      class="pc-command-dialog"
      phx-hook="PetalCommandDialog"
      data-shortcut={@shortcut}
      data-reset-on-close={@reset_on_close && "true"}
    >
      <div
        id={"#{@id}-palette"}
        class={["pc-command", @class]}
        phx-hook="PetalCommand"
        data-loop={@loop && "true"}
        {@rest}
      >
        {render_slot(@inner_block)}
      </div>
    </dialog>
    """
  end

  @doc """
  Returns a `JS` command that opens the command dialog with the given id.
  Compose it onto any trigger: `phx-click={open_command("cmdk")}`.
  """
  def open_command(js \\ %JS{}, id) when is_binary(id) do
    JS.dispatch(js, "pc:command-open", to: "##{id}")
  end

  attr :placeholder, :string, default: "Type a command or search..."

  attr :autofocus, :boolean,
    default: false,
    doc: "focus the input on mount (dialogs focus it on open regardless)"

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "The search field. Keyboard focus lives here; the list highlight is virtual."
  def command_input(assigns) do
    ~H"""
    <div class="pc-command__input-wrap">
      <.icon name="hero-magnifying-glass" class="pc-command__input-icon" />
      <input
        type="text"
        class={["pc-command__input", @class]}
        placeholder={@placeholder}
        autofocus={@autofocus}
        role="combobox"
        aria-expanded="true"
        aria-autocomplete="list"
        autocomplete="off"
        autocorrect="off"
        spellcheck="false"
        {@rest}
      />
    </div>
    """
  end

  attr :label, :string, default: "Commands", doc: "accessible name for the listbox"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Scrollable container for groups and items."
  def command_list(assigns) do
    ~H"""
    <div class={["pc-command__list", @class]} role="listbox" aria-label={@label} {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Shown only when the query matches nothing."
  def command_empty(assigns) do
    ~H"""
    <div class={["pc-command__empty", @class]} data-pc-command-empty hidden {@rest}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :heading, :string, default: nil, doc: "group heading, rendered above the items"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "Groups related items. Hides itself when every item inside is filtered out."
  def command_group(assigns) do
    ~H"""
    <div class={["pc-command__group", @class]} role="group" data-pc-command-group {@rest}>
      <div :if={@heading} class="pc-command__group-heading" aria-hidden="true">{@heading}</div>
      {render_slot(@inner_block)}
    </div>
    """
  end

  attr :value, :string,
    default: nil,
    doc: "the text the filter matches against. Defaults to the item's visible text"

  attr :keywords, :list, default: [], doc: "extra search aliases for this item"
  attr :disabled, :boolean, default: false
  attr :navigate, :string, default: nil, doc: "live_redirect target - renders the item as a link"
  attr :patch, :string, default: nil, doc: "live_patch target - renders the item as a link"
  attr :href, :string, default: nil, doc: "plain link target - renders the item as a link"
  attr :class, :any, default: nil

  attr :rest, :global,
    include: ~w(target rel method download),
    doc: "phx-click and friends work here - Enter clicks the highlighted item"

  slot :inner_block, required: true

  @doc """
  One entry in the palette. A link when `navigate`/`patch`/`href` is set,
  a button otherwise. `value` (plus `keywords`) is what typing matches;
  it defaults to the item's visible text.
  """
  def command_item(assigns) do
    assigns = assign(assigns, :link?, !!(assigns.navigate || assigns.patch || assigns.href))

    ~H"""
    <.link
      :if={@link?}
      navigate={@navigate}
      patch={@patch}
      href={@href}
      class={["pc-command__item", @class]}
      role="option"
      aria-selected="false"
      data-pc-command-item
      data-value={@value}
      data-keywords={Enum.join(@keywords, " ")}
      data-disabled={@disabled && "true"}
      aria-disabled={@disabled && "true"}
      tabindex="-1"
      {@rest}
    >
      {render_slot(@inner_block)}
    </.link>
    <button
      :if={!@link?}
      type="button"
      class={["pc-command__item", @class]}
      role="option"
      aria-selected="false"
      data-pc-command-item
      data-value={@value}
      data-keywords={Enum.join(@keywords, " ")}
      data-disabled={@disabled && "true"}
      disabled={@disabled}
      tabindex="-1"
      {@rest}
    >
      {render_slot(@inner_block)}
    </button>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global

  @doc "A hairline between groups. Hidden automatically while a query is active."
  def command_separator(assigns) do
    ~H"""
    <div
      class={["pc-command__separator", @class]}
      role="separator"
      data-pc-command-separator
      {@rest}
    >
    </div>
    """
  end

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  @doc "A right-aligned keyboard hint inside an item."
  def command_shortcut(assigns) do
    ~H"""
    <span class={["pc-command__shortcut", @class]} {@rest}>
      {render_slot(@inner_block)}
    </span>
    """
  end
end
