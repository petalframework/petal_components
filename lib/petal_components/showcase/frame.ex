defmodule PetalComponents.Showcase.Frame do
  @moduledoc """
  The shared presentation shell for showcase examples - the piece that makes the
  dev playground and petal.build render example blocks identically.

  `showcase_example/1` joins a live preview to a collapsible, syntax-highlighted
  code panel with a copy button. The collapse toggle is pure CSS (a hidden
  checkbox + `:has()` rules in `default.css`) so it needs no Alpine and no hook
  and works in dead views. Code is highlighted server-side via the optional
  `mdex` + `lumis` stack (same as the chat), falling back to plain `<pre>` markup
  when they are absent.

  `showcase_props/1` renders a component's attrs/slots table straight from
  `Phoenix.Component.__components__/0`, so props documentation can never drift.
  """
  use Phoenix.Component
  import PetalComponents.Icon

  alias PetalComponents.Showcase.Example

  attr :example, Example, required: true

  attr :id, :string,
    default: nil,
    doc:
      "DOM id for the frame; defaults to one derived from the example id. Set it if the same example renders twice on one page"

  attr :locked, :boolean,
    default: false,
    doc: "blur the code behind a login CTA (the surface decides)"

  attr :show_code, :boolean, default: true

  attr :content_left, :boolean,
    default: false,
    doc: "left-align the preview instead of centering it"

  attr :class, :any, default: nil
  slot :locked_overlay, doc: "shown over the blurred code when locked; defaults to a lock hint"

  @doc "Renders one showcase example: preview panel + collapsible code panel."
  def showcase_example(assigns) do
    # The id must be deterministic (derived from the example, not a counter):
    # LiveView re-renders regenerate function-component assigns, and a changing
    # id would defeat the phx-update="ignore" below, resetting the user's
    # expanded/collapsed state on every patch.
    assigns =
      assigns
      |> assign(:frame_id, assigns.id || "pcsx-#{assigns.example.id}")
      |> assign(:collapsible, collapsible?(assigns.example.code))
      |> assign(:code_html, code_html(assigns.example))

    ~H"""
    <div id={@frame_id} class={["pc-showcase not-prose", @class]}>
      <div class={["pc-showcase__preview", !@content_left && "pc-showcase__preview--center"]}>
        {@example.render.(assigns)}
      </div>

      <%!-- phx-update="ignore": the panel is static content and the checkbox
      holds client-side UI state (expanded/collapsed). Without this, any
      LiveView patch on the page would reset an opened panel - the original
      marketing implementation carried the same guard. --%>
      <div :if={@show_code} id={"#{@frame_id}-code"} phx-update="ignore" class="pc-showcase-code">
        <input
          type="checkbox"
          id={"#{@frame_id}-toggle"}
          class="pc-showcase-code__toggle sr-only"
          checked={!@collapsible}
          aria-label="Show the code for this example"
        />

        <div class="pc-showcase-code__bar">
          <span class="pc-showcase-code__lang">heex</span>
          <button
            :if={!@locked}
            type="button"
            id={"#{@frame_id}-copy"}
            class="pc-showcase-code__copy"
            phx-hook="PetalCopy"
            data-copy-text={@example.code}
            data-copied-label="Copied!"
          >
            <span data-pc-copy-label class="inline-flex items-center gap-1.5">
              <.icon name="hero-clipboard" class="w-3.5 h-3.5" />
              <span data-pc-copy-default>Copy</span>
              <span data-pc-copy-done class="hidden">Copied!</span>
            </span>
          </button>
        </div>

        <div class="pc-showcase-code__scroll">
          {Phoenix.HTML.raw(@code_html)}

          <%= if @locked do %>
            <div class="pc-showcase-code__lock">
              <%= if @locked_overlay != [] do %>
                {render_slot(@locked_overlay)}
              <% else %>
                <span class="pc-showcase-code__lock-hint">
                  <.icon name="hero-lock-closed" class="w-4 h-4" /> Log in to view
                </span>
              <% end %>
            </div>
          <% else %>
            <label :if={@collapsible} for={"#{@frame_id}-toggle"} class="pc-showcase-code__peek">
              <span class="pc-showcase-code__peek-btn">
                <.icon name="hero-code-bracket" class="w-4 h-4" /> View Code
              </span>
            </label>
          <% end %>
        </div>

        <label
          :if={!@locked && @collapsible}
          for={"#{@frame_id}-toggle"}
          class="pc-showcase-code__hide"
        >
          <.icon name="hero-chevron-up" class="w-3.5 h-3.5" /> Hide Code
        </label>
      </div>
    </div>
    """
  end

  # Short snippets fit inside the collapsed height, so there is nothing to reveal.
  defp collapsible?(code) when is_binary(code) do
    code |> String.trim() |> String.split("\n") |> length() > 5
  end

  # Precompiled highlight (Phase 1) wins; otherwise highlight now via mdex/lumis;
  # otherwise a plain escaped <pre> that a client highlighter could still colour.
  defp code_html(%Example{highlighted: {:safe, html}}), do: html

  defp code_html(%Example{code: code}) do
    if Code.ensure_loaded?(MDEx) and Code.ensure_loaded?(PetalComponents.Chat) do
      # Never let a highlighter misconfiguration (e.g. lumis present but
      # unconfigured, which raises) take down a page - fall back to plain code.
      try do
        PetalComponents.Chat.to_html("```heex\n" <> code <> "\n```")
      rescue
        _ -> fallback_pre(code)
      end
    else
      fallback_pre(code)
    end
  end

  defp fallback_pre(code) do
    escaped = code |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

    ~s(<pre class="pc-showcase-code__fallback"><code class="language-heex">#{escaped}</code></pre>)
  end

  attr :component, :atom,
    required: true,
    doc: "the component module, e.g. PetalComponents.Chat"

  attr :function, :atom, default: nil, doc: "a single component function, e.g. :border_beam"

  attr :functions, :list,
    default: nil,
    doc:
      "several functions to document (one table each) - for multi-function components like chat"

  attr :class, :any, default: nil

  @doc """
  Renders a component's attributes and slots as a table (one per function),
  straight from `Phoenix.Component.__components__/0` - so props docs can never
  drift from the component's real API. Pass `function` for a single-function
  component, or `functions` for a multi-function one (chat, command).
  """
  def showcase_props(assigns) do
    funcs = assigns.functions || List.wrap(assigns.function)
    defs = assigns.component.__components__()

    tables =
      Enum.map(funcs, fn f ->
        info = Map.get(defs, f, %{attrs: [], slots: []})
        %{name: f, attrs: info.attrs, slots: info.slots}
      end)

    assigns = assign(assigns, tables: tables, multi: length(tables) > 1)

    ~H"""
    <div class={["pc-showcase-props not-prose", @class]}>
      <div :for={t <- @tables} class="pc-showcase-props__group">
        <div :if={@multi} class="pc-showcase-props__fn">&lt;.{t.name}&gt;</div>
        <table class="pc-showcase-props__table">
          <thead>
            <tr>
              <th>Attribute</th>
              <th>Type</th>
              <th>Default</th>
              <th>Description</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={a <- t.attrs}>
              <td>
                <code class="pc-showcase-props__name">{a.name}</code><span
                  :if={a.required}
                  class="pc-showcase-props__req"
                  title="required"
                >*</span>
              </td>
              <td><code class="pc-showcase-props__type">{format_type(a.type)}</code></td>
              <td>
                <code :if={Keyword.has_key?(a.opts, :default)} class="pc-showcase-props__default">{inspect(
                  a.opts[:default]
                )}</code>
              </td>
              <td>
                {a.doc}
                <div :if={a.opts[:values]} class="pc-showcase-props__values">
                  one of: {Enum.map_join(a.opts[:values], ", ", &inspect/1)}
                </div>
              </td>
            </tr>
            <tr :for={s <- t.slots}>
              <td>
                <code class="pc-showcase-props__name">:{s.name}</code>
                <span class="pc-showcase-props__slot">slot</span>
              </td>
              <td><code class="pc-showcase-props__type">slot</code></td>
              <td></td>
              <td>{s.doc}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp format_type(type) when is_atom(type), do: to_string(type)
  defp format_type(type), do: inspect(type)
end
