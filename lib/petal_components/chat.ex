defmodule PetalComponents.Chat do
  @moduledoc """
  AI chat / conversation components — the LiveView-native answer to React's
  AI Elements / assistant-ui. Build streaming chat UIs without a client AI SDK:
  tokens stream over the LiveView socket you already have.

  Components:

    * `conversation/1`  — scrollable thread container (slot-driven)
    * `chat_message/1`  — a single message bubble (user or assistant)
    * `streaming_text/1` — token-by-token output via the `PetalChatStream` JS hook
    * `prompt_input/1`   — the composer (textarea + send)

  ## Importing

  Unlike the core components, `Chat` is **not** brought in by `use PetalComponents`
  — it defines generic names (`markdown/1`, `reasoning/1`, …) that would clash with
  your app's own helpers. Alias it and call it namespaced:

      alias PetalComponents.Chat

      <Chat.conversation id="chat">
        <Chat.chat_message role="assistant"><Chat.markdown content={@text} /></Chat.chat_message>
      </Chat.conversation>

  The examples below use that `Chat.` prefix.

  ## Streaming

  `streaming_text/1` is driven by the bundled `PetalChatStream` JS hook. The
  parent LiveView pushes each delta and the hook appends it to the bubble:

      # per Gemini/OpenAI delta:
      socket = push_event(socket, "pc-chat-token", %{id: "answer", text: delta})

      <Chat.streaming_text id="answer" />

  Register the hooks once in your LiveSocket:

      import PetalComponents from "../../deps/petal_components/assets/js/petal_components"
      new LiveSocket("/live", Socket, { hooks: { ...PetalComponents }, ... })

  ## Styling

  Every component takes a `class` that is appended last (CSS specificity wins,
  matching the rest of petal_components). Theme tokens are exposed as CSS
  variables (`--pc-chat-*`) for reskinning without touching markup, and any part
  can be fully replaced via slots.
  """
  use Phoenix.Component

  @doc """
  A scrollable conversation thread. Composition-first: drop `chat_message/1`,
  `streaming_text/1`, or your own markup inside.

  Opens scrolled to the latest message. When older history is inserted above
  (pagination), the reader's position is preserved - give thread rows stable
  `id`s (or render them from a LiveView stream) so patches reuse the DOM
  nodes; without ids, LiveView rebuilds the siblings and the browser resets
  the scroll.

      <Chat.conversation>
        <Chat.chat_message :for={msg <- @messages} role={msg.role}>{msg.text}</Chat.chat_message>
        <:footer>
          <Chat.prompt_input phx-submit="send" loading={@streaming?} />
        </:footer>
      </Chat.conversation>
  """
  attr :id, :string, doc: "defaults to a generated id so multiple threads can coexist"

  attr :variant, :string,
    default: "plain",
    values: ["plain", "bubbles"],
    doc:
      "plain is the AI convention (ChatGPT/Claude): assistant text sits on the surface, only the user gets a bubble. bubbles puts both sides in bubbles (messenger style)"

  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :footer, doc: "pinned below the scroll area, e.g. a prompt_input"

  def conversation(assigns) do
    assigns = assign_new(assigns, :id, fn -> "pc-chat-#{Ecto.UUID.generate()}" end)

    ~H"""
    <div class={["pc-chat", @variant == "plain" && "pc-chat--plain", @class]} {@rest}>
      <div class="pc-chat__viewport">
        <div
          id={@id}
          data-pc-scroll
          phx-hook="PetalChatScroll"
          role="log"
          aria-live="polite"
          class="pc-chat__thread"
        >
          {render_slot(@inner_block)}
        </div>
        <button
          type="button"
          data-pc-scroll-btn
          class="pc-chat__scroll-btn pc-chat__scroll-btn--hidden"
          aria-label="Scroll to latest"
        >
          ↓
        </button>
      </div>
      <div :if={@footer != []} class="pc-chat__footer">
        {render_slot(@footer)}
      </div>
    </div>
    """
  end

  @doc """
  A single message bubble.

  Default markup, or replace it entirely — the `class` is appended last so your
  utilities win, and the `:inner_block` is yours to fill.
  """
  attr :role, :string, default: "assistant", values: ["user", "assistant", "system"]
  attr :class, :any, default: nil
  attr :rest, :global
  slot :avatar, doc: "optional leading avatar/icon"

  slot :actions,
    doc:
      "an action bar rendered below the message, outside the bubble - message_actions/1. Works on any role: copy/edit under a user message, copy/feedback/regenerate under an assistant one"

  slot :inner_block, required: true

  def chat_message(assigns) do
    ~H"""
    <div class={["pc-chat__row", "pc-chat__row--#{@role}", @class]} {@rest}>
      <div :if={@avatar != []} class="pc-chat__avatar">{render_slot(@avatar)}</div>
      <div class="pc-chat__body">
        <div class={["pc-chat__bubble", "pc-chat__bubble--#{@role}"]}>
          {render_slot(@inner_block)}
        </div>
        <div :if={@actions != []} class="pc-chat__row-actions">{render_slot(@actions)}</div>
      </div>
    </div>
    """
  end

  @doc """
  Token-by-token streaming output, driven by the `PetalChatStream` JS hook.

  Render this in the in-progress assistant bubble. The parent LiveView pushes
  each delta to it:

      socket = push_event(socket, "pc-chat-token", %{id: "answer", text: delta})

      <Chat.streaming_text id="answer" />

  Until the first token lands it shows a typing indicator; on the first token it
  swaps to live text with a blinking caret. The element owns its own DOM
  (`phx-update="ignore"`), so no re-render clobbers the streamed text.
  """
  attr :id, :string, required: true
  attr :event, :string, default: "pc-chat-token", doc: "push_event name the hook listens for"

  attr :format, :string,
    default: "text",
    values: ["text", "markdown"],
    doc:
      ~s|"text" appends raw token deltas; "markdown" replaces innerHTML with rendered HTML you push (see `to_html/1`)|

  attr :class, :any, default: nil

  def streaming_text(assigns) do
    ~H"""
    <span
      id={@id}
      phx-hook="PetalChatStream"
      phx-update="ignore"
      data-event={@event}
      class={["pc-chat__stream", @class]}
    >
      <span class="pc-chat__typing" aria-hidden="true"><span></span><span></span><span></span></span>
      <span :if={@format == "text"} data-pc-stream-text class="pc-chat__stream-text"></span><span
        :if={@format == "text"}
        class="pc-chat__caret"
        aria-hidden="true"
      ></span>
      <div :if={@format == "markdown"} data-pc-stream-html class="pc-chat__markdown"></div>
    </span>
    """
  end

  @doc """
  Render markdown to sanitized, syntax-highlighted HTML using the same engine
  the `markdown/1` component uses. Use it to live-stream markdown: throttle calls
  on your growing buffer and `push_event` the result to a `format="markdown"`
  `streaming_text/1`:

      socket = push_event(socket, "pc-chat-token", %{id: "answer", html: PetalComponents.Chat.to_html(buffer)})
  """
  def to_html(content), do: render_markdown(content)

  defp ensure_mdex! do
    if Code.ensure_loaded?(MDEx) do
      :ok
    else
      raise """
      PetalComponents.Chat markdown rendering requires the optional :mdex dependency.

      Add it to your deps:

          {:mdex, "~> 0.12"}
      """
    end
  end

  @doc """
  A tool-call card — the chrome around a generative-UI widget.

  This is the "AI Elements" pattern done LiveView-native: the model emits a
  structured tool call (function calling), you map the tool name to one of your
  registered Phoenix components, and render it inside this card. The widget is a
  real LiveView component — it can have its own `phx-click`, forms, streams.

      <Chat.tool_call name="get_weather" status={:complete}>
        <.weather_card city={@args["city"]} temp={@result.temp} />
      </Chat.tool_call>

  `status` drives the header affordance: `:running` shows a spinner, `:complete`
  a check, `:error` a warning.
  """
  attr :name, :string, required: true
  attr :status, :atom, default: :complete, values: [:running, :complete, :error]
  attr :label, :string, default: nil, doc: "human label; defaults to the tool name"
  attr :class, :any, default: nil
  slot :inner_block, doc: "the rendered widget / tool result"

  def tool_call(assigns) do
    ~H"""
    <div class={["pc-chat__tool", "pc-chat__tool--#{@status}", @class]}>
      <div class="pc-chat__tool-header">
        <.tool_status_icon status={@status} />
        <span class="pc-chat__tool-name">{@label || @name}</span>
      </div>
      <div :if={@inner_block != []} class="pc-chat__tool-body">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  attr :status, :atom, required: true

  defp tool_status_icon(%{status: :running} = assigns),
    do: ~H|<span class="pc-chat__tool-spinner" aria-hidden="true"></span>|

  defp tool_status_icon(%{status: :error} = assigns),
    do: ~H|<span class="pc-chat__tool-error" aria-hidden="true">!</span>|

  defp tool_status_icon(assigns),
    do: ~H|<span class="pc-chat__tool-check" aria-hidden="true">✓</span>|

  @doc """
  Renders markdown as sanitized, syntax-highlighted HTML (via MDEx). Use it for
  committed assistant messages so headings, lists, tables and code blocks render
  properly:

      <Chat.chat_message role="assistant"><Chat.markdown content={msg.text} /></Chat.chat_message>

  Output is sanitized server-side — model text is never rendered as live markup.

  > #### Markdown is rendered faithfully {: .info}
  >
  > Code blocks come from the model's own fences. If a model wraps an example
  > that itself contains a ` ``` ` fence inside another same-length ` ``` ` fence,
  > that is invalid CommonMark and renders broken (the outer fence closes early) —
  > every CommonMark renderer behaves this way. Steer the model with a system
  > prompt: "when showing example markdown that contains code fences, wrap the
  > outer block in MORE backticks than the inner fence."
  """
  attr :content, :string, required: true
  attr :id, :string, default: nil, doc: "pass a unique id to enable per-code-block copy buttons"
  attr :class, :any, default: nil

  def markdown(assigns) do
    assigns = assign(assigns, :html, render_markdown(assigns.content))

    ~H"""
    <div id={@id} phx-hook={@id && "PetalCodeCopy"} class={["pc-chat__markdown", @class]}>
      {Phoenix.HTML.raw(@html)}
    </div>
    """
  end

  @doc """
  Markdown with inline widget directives ("MDX for Phoenix").

  The model can drop a widget mid-prose with a fenced block tagged
  ` ```widget:<name> ` containing JSON args. Everything else renders as normal
  markdown (normal code fences like ` ```elixir ` are untouched). You supply a
  `render_widget` function that maps a name + args to a rendered component:

      <Chat.rich_text
        content={@text}
        render_widget={fn
          "weather", args -> ~H"<.weather_card city={args["city"]} .../>"
          _, _ -> nil
        end}
      />

  Example model output:

      Here's the forecast:

      ```widget:weather
      {"city": "Paris"}
      ```

      Pack an umbrella.
  """
  @widget_fence ~r/```widget:([a-zA-Z0-9_-]+)\s*\n(.*?)\n```/s

  attr :content, :string, required: true

  attr :render_widget, :any,
    default: nil,
    doc: "fn(name :: String.t(), args :: map) -> rendered | nil"

  attr :class, :any, default: nil

  def rich_text(assigns) do
    assigns = assign(assigns, :segments, split_widgets(assigns.content))

    ~H"""
    <div class={["pc-chat__markdown", @class]}>
      <%= for seg <- @segments do %>
        <%= case seg do %>
          <% {:html, html} -> %>
            {Phoenix.HTML.raw(html)}
          <% {:widget, name, args} -> %>
            {@render_widget && @render_widget.(name, args)}
        <% end %>
      <% end %>
    </div>
    """
  end

  defp split_widgets(nil), do: []

  defp split_widgets(content) do
    @widget_fence
    |> Regex.split(content, include_captures: true)
    |> Enum.flat_map(fn part ->
      case Regex.run(@widget_fence, part) do
        [_, name, json] ->
          case Jason.decode(json) do
            {:ok, args} -> [{:widget, name, args}]
            _ -> [{:html, render_markdown(part)}]
          end

        _ ->
          case String.trim(part) do
            "" -> []
            _ -> [{:html, render_markdown(part)}]
          end
      end
    end)
  end

  # Built at runtime (not as a module attribute) so MDEx stays a truly optional
  # dependency — referencing MDEx.Document here at compile time would force every
  # consumer to pull in :mdex just to compile, even if they never call markdown/1.
  defp markdown_opts do
    [
      extension: [strikethrough: true, table: true, autolink: true, tasklist: true],
      syntax_highlight: [formatter: :html_inline],
      sanitize: MDEx.Document.default_sanitize_options()
    ]
  end

  @doc """
  The composer. Wraps a form; pass `phx-submit` (and optionally `phx-change`)
  through the global attrs.

      <Chat.prompt_input phx-submit="send" phx-change="draft" value={@draft} loading={@streaming?} on_stop="stop" />

  While `loading`, the input stays editable (so you can draft your next message)
  and the send button becomes a stop button that pushes `on_stop` — wire it to
  cancel your generation task.
  """
  attr :id, :string, doc: "defaults to a generated id so multiple composers can coexist"

  attr :name, :string, default: "prompt"

  attr :value, :string,
    default: "",
    doc:
      "initial textarea value. The field is uncontrolled after mount (phx-update=ignore, so keystrokes never re-render and lose focus); set it later - edit, quote, clear - by pushing a `pc-chat-set-input` event (`%{value: text}`, optional `%{id: composer_id}`) to the PetalChatComposer hook"

  attr :placeholder, :string, default: "Send a message..."
  attr :aria_label, :string, default: "Message", doc: "accessible label for the textarea"
  attr :loading, :boolean, default: false

  attr :on_stop, :string,
    default: nil,
    doc: "event pushed when the stop button is clicked while loading"

  attr :submit_label, :string,
    default: nil,
    doc: "text for the send button; the default is the arrow-up icon convention"

  attr :editing, :boolean,
    default: false,
    doc: "show the edit-mode banner above the field (set while editing a past message)"

  attr :edit_label, :string, default: "Editing message", doc: "label shown in the edit banner"

  attr :on_cancel_edit, :string,
    default: nil,
    doc: "event pushed when the edit banner's cancel (X) is clicked"

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-submit phx-change phx-target)
  slot :actions, doc: "extra controls left of the send button"

  def prompt_input(assigns) do
    assigns = assign_new(assigns, :id, fn -> "pc-chat-composer-#{Ecto.UUID.generate()}" end)

    ~H"""
    <form
      id={@id}
      phx-hook="PetalChatComposer"
      class={["pc-chat__composer", @editing && "pc-chat__composer--editing", @class]}
      {@rest}
    >
      <div :if={@editing} class="pc-chat__composer-banner">
        <span class="pc-chat__composer-banner-label">
          <PetalComponents.Icon.icon name="hero-pencil-square" class="pc-chat__composer-banner-icon" />
          {@edit_label}
        </span>
        <button
          :if={@on_cancel_edit}
          type="button"
          phx-click={@on_cancel_edit}
          aria-label="Cancel edit"
          class="pc-chat__composer-banner-cancel"
        >
          <PetalComponents.Icon.icon name="hero-x-mark" class="pc-chat__composer-banner-icon" />
        </button>
      </div>
      <div class="pc-chat__composer-row">
        <textarea
          id={"#{@id}-input"}
          name={@name}
          phx-update="ignore"
          rows="1"
          placeholder={@placeholder}
          aria-label={@aria_label}
          autocomplete="off"
          class="pc-chat__composer-input"
        >{@value}</textarea>
        <div :if={@actions != []} class="pc-chat__composer-actions">{render_slot(@actions)}</div>
        <button
          :if={!@loading}
          type="submit"
          class={["pc-chat__composer-send", !@submit_label && "pc-chat__composer-send--icon"]}
          aria-label={if !@submit_label, do: "Send message"}
        >
          <%= if @submit_label do %>
            {@submit_label}
          <% else %>
            <PetalComponents.Icon.icon name="hero-arrow-up" class="pc-chat__composer-send-icon" />
          <% end %>
        </button>
        <button
          :if={@loading && @on_stop}
          type="button"
          phx-click={@on_stop}
          aria-label="Stop generating"
          class="pc-chat__composer-stop"
        >
          <span class="pc-chat__stop-icon" aria-hidden="true"></span>
        </button>
        <button
          :if={@loading && !@on_stop}
          type="button"
          disabled
          aria-label="Sending"
          class={["pc-chat__composer-send", !@submit_label && "pc-chat__composer-send--icon"]}
        >
          <%= if @submit_label do %>
            …
          <% else %>
            <PetalComponents.Icon.icon name="hero-arrow-up" class="pc-chat__composer-send-icon" />
          <% end %>
        </button>
      </div>
    </form>
    """
  end

  @doc """
  A collapsible "thinking" / reasoning block for reasoning-model output. Native
  `<details>`, so no JS.

      <Chat.reasoning>Chain of thought here...</Chat.reasoning>
      <Chat.reasoning label="Thought for 3s" open>...</Chat.reasoning>
  """
  attr :label, :string, default: "Reasoning"
  attr :open, :boolean, default: false
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def reasoning(assigns) do
    ~H"""
    <details class={["pc-chat__reasoning", @class]} open={@open}>
      <summary class="pc-chat__reasoning-summary">
        <PetalComponents.Icon.icon name="hero-chevron-right" class="pc-chat__reasoning-chevron" />
        {@label}
      </summary>
      <div class="pc-chat__reasoning-body">{render_slot(@inner_block)}</div>
    </details>
    """
  end

  @doc """
  An inline conversation marker - a system note, a status row, or a labelled
  separator between sections of the thread.

      <Chat.marker icon="hero-magnifying-glass">Searched the web</Chat.marker>
      <Chat.marker variant="separator">Today</Chat.marker>
      <Chat.marker variant="border" icon="hero-check-circle">Context compacted</Chat.marker>
      <Chat.marker loading>Thinking...</Chat.marker>

  While `loading` it shows a small spinner and announces as a live status
  region. For the shimmering streaming-status treatment, compose the existing
  `PetalComponents.TextAnimation.shimmer_text/1` inside:

      <Chat.marker loading><.shimmer_text>Running the numbers...</.shimmer_text></Chat.marker>
  """
  attr :variant, :string,
    default: "inline",
    values: ["inline", "separator", "border"],
    doc: "inline note, centred labelled separator, or a full-width bordered row"

  attr :icon, :string, default: nil, doc: "heroicon name rendered before the text"
  attr :loading, :boolean, default: false, doc: "spinner + role=status for in-progress work"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true

  def marker(assigns) do
    ~H"""
    <div
      class={["pc-chat__marker", "pc-chat__marker--#{@variant}", @class]}
      role={if @loading, do: "status"}
      {@rest}
    >
      <span :if={@loading} class="pc-chat__marker-spinner" aria-hidden="true"></span>
      <PetalComponents.Icon.icon
        :if={@icon && !@loading}
        name={@icon}
        class="pc-chat__marker-icon"
      />
      <span class="pc-chat__marker-text">{render_slot(@inner_block)}</span>
    </div>
    """
  end

  @doc """
  A row of actions under a message - the copy / feedback / regenerate bar.
  Compose with `copy_button/1`, `action_button/1`, or your own `phx-click`
  buttons using the `pc-chat__action` class.

      <Chat.message_actions>
        <Chat.copy_button id={"copy-\#{@id}"} text={@text} icon />
        <Chat.action_button icon="hero-hand-thumb-up" label="Good response" phx-click="feedback" phx-value-vote="up" />
        <Chat.action_button icon="hero-arrow-path" label="Regenerate" phx-click="regenerate" />
      </Chat.message_actions>

  `visible="hover"` fades the bar in when the message row is hovered or
  focused (ChatGPT-style density for long threads). Touch devices have no
  hover, so there the bar always shows.
  """
  attr :visible, :string,
    default: "always",
    values: ["always", "hover"],
    doc: "hover reveals the bar on message-row hover/focus; always shows on touch"

  attr :class, :any, default: nil
  slot :inner_block, required: true

  def message_actions(assigns) do
    ~H"""
    <div class={["pc-chat__actions", @visible == "hover" && "pc-chat__actions--hover", @class]}>
      {render_slot(@inner_block)}
    </div>
    """
  end

  @doc """
  An icon action for the message bar - thumbs up/down, regenerate, share.
  Icon-only with the accessible name on `label` (also the tooltip). Pass any
  `phx-*` binding through.

      <Chat.action_button icon="hero-hand-thumb-up" label="Good response" phx-click="feedback" phx-value-vote="up" />
  """
  attr :icon, :string, required: true, doc: "heroicon name"
  attr :label, :string, required: true, doc: "accessible name, also shown as the tooltip"
  attr :class, :any, default: nil
  attr :rest, :global

  def action_button(assigns) do
    ~H"""
    <button
      type="button"
      class={["pc-chat__action pc-chat__action--icon", @class]}
      aria-label={@label}
      title={@label}
      {@rest}
    >
      <PetalComponents.Icon.icon name={@icon} class="pc-chat__action-icon" />
    </button>
    """
  end

  @doc """
  A copy-to-clipboard button (via the `PetalCopy` hook). Shows brief feedback -
  the text flips to "Copied!", or in `icon` mode the clipboard swaps to a
  check. Requires a unique `id`.
  """
  attr :id, :string, required: true
  attr :text, :string, required: true, doc: "the text to copy"
  attr :label, :string, default: "Copy"
  attr :icon, :boolean, default: false, doc: "icon-only (clipboard -> check feedback)"
  attr :class, :any, default: nil

  def copy_button(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      phx-hook="PetalCopy"
      data-copy-text={@text}
      data-copied-label="Copied!"
      class={["pc-chat__action", @icon && "pc-chat__action--icon", @class]}
      aria-label={if @icon, do: @label}
      title={if @icon, do: @label}
    >
      <%= if @icon do %>
        <span data-pc-copy-default>
          <PetalComponents.Icon.icon name="hero-clipboard" class="pc-chat__action-icon" />
        </span>
        <span data-pc-copy-done class="hidden">
          <PetalComponents.Icon.icon name="hero-check" class="pc-chat__action-icon text-success-500" />
        </span>
      <% else %>
        <span data-pc-copy-label>{@label}</span>
      <% end %>
    </button>
    """
  end

  @doc """
  Clickable prompt-starter chips for an empty state. Each pushes `on_select`
  with `phx-value-prompt` set to the suggestion.

      <Chat.suggestions items={["Summarise this", "Write tests"]} on_select="suggest" />
  """
  attr :items, :list, required: true
  attr :on_select, :string, default: "suggestion", doc: "event pushed with phx-value-prompt"
  attr :class, :any, default: nil

  def suggestions(assigns) do
    ~H"""
    <div class={["pc-chat__suggestions", @class]}>
      <button
        :for={item <- @items}
        type="button"
        phx-click={@on_select}
        phx-value-prompt={item}
        class="pc-chat__suggestion"
      >
        {item}
      </button>
    </div>
    """
  end

  @doc """
  An error notice with an optional retry button.

      <Chat.chat_error on_retry="retry">Something went wrong.</Chat.chat_error>
  """
  attr :on_retry, :string, default: nil
  attr :retry_label, :string, default: "Retry"
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def chat_error(assigns) do
    ~H"""
    <div class={["pc-chat__error", @class]} role="alert">
      <span class="pc-chat__error-text">{render_slot(@inner_block)}</span>
      <button :if={@on_retry} type="button" phx-click={@on_retry} class="pc-chat__retry">
        {@retry_label}
      </button>
    </div>
    """
  end

  defp render_markdown(nil), do: ""

  defp render_markdown(content) do
    ensure_mdex!()

    result =
      try do
        MDEx.to_html(content, markdown_opts())
      rescue
        ArgumentError -> :lumis_unavailable
      end

    case result do
      {:ok, html} ->
        external_links(html)

      reason when reason in [:lumis_not_enabled, :lumis_unavailable] ->
        # Lumis NIF unavailable or not configured — render without syntax highlighting
        fallback = Keyword.delete(markdown_opts(), :syntax_highlight)

        case MDEx.to_html(content, fallback) do
          {:ok, html} -> external_links(html)
          _ -> content |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
        end

      {:error, _} ->
        content |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    end
  end

  # Sanitizer already adds rel="noopener noreferrer"; open links in a new tab so
  # clicking one doesn't navigate away from the chat.
  defp external_links(html), do: String.replace(html, "<a href=", ~s(<a target="_blank" href=))
end
