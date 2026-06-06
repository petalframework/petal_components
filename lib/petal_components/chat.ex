defmodule PetalComponents.Chat do
  @moduledoc """
  AI chat / conversation components — the LiveView-native answer to React's
  AI Elements / assistant-ui. Build streaming chat UIs without a client AI SDK:
  tokens stream over the LiveView socket you already have.

  Components:

    * `conversation/1`  — scrollable thread container (slot-driven)
    * `chat_message/1`  — a single message bubble (user or assistant)
    * `streaming_text/1` — token-by-token output via `phx-update="stream"`, no JS hook
    * `prompt_input/1`   — the composer (textarea + send)

  ## Streaming

  `streaming_text/1` is driven by the bundled `PetalChatStream` JS hook. The
  parent LiveView pushes each delta and the hook appends it to the bubble:

      # per Gemini/OpenAI delta:
      socket = push_event(socket, "pc-chat-token", %{id: "answer", text: delta})

      <.streaming_text id="answer" />

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

      <.conversation>
        <.chat_message :for={msg <- @messages} role={msg.role}>{msg.text}</.chat_message>
        <:footer>
          <.prompt_input phx-submit="send" loading={@streaming?} />
        </:footer>
      </.conversation>
  """
  attr :id, :string, default: "conversation"
  attr :class, :any, default: nil
  attr :rest, :global
  slot :inner_block, required: true
  slot :footer, doc: "pinned below the scroll area, e.g. a prompt_input"

  def conversation(assigns) do
    ~H"""
    <div class={["pc-chat", @class]} {@rest}>
      <div class="pc-chat__viewport">
        <div id={@id} data-pc-scroll phx-hook="PetalChatScroll" role="log" aria-live="polite" class="pc-chat__thread">
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
  slot :inner_block, required: true

  def chat_message(assigns) do
    ~H"""
    <div class={["pc-chat__row", "pc-chat__row--#{@role}", @class]} {@rest}>
      <div :if={@avatar != []} class="pc-chat__avatar">{render_slot(@avatar)}</div>
      <div class={["pc-chat__bubble", "pc-chat__bubble--#{@role}"]}>{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc """
  Token-by-token streaming output, driven by the `PetalChatStream` JS hook.

  Render this in the in-progress assistant bubble. The parent LiveView pushes
  each delta to it:

      socket = push_event(socket, "pc-chat-token", %{id: "answer", text: delta})

      <.streaming_text id="answer" />

  Until the first token lands it shows a typing indicator; on the first token it
  swaps to live text with a blinking caret. The element owns its own DOM
  (`phx-update="ignore"`), so no re-render clobbers the streamed text.
  """
  attr :id, :string, required: true
  attr :event, :string, default: "pc-chat-token", doc: "push_event name the hook listens for"
  attr :class, :any, default: nil

  def streaming_text(assigns) do
    # NB: the inner spans are deliberately adjacent with no whitespace between
    # them — the bubble uses `whitespace-pre-wrap`, so any newline/indentation
    # here would render as blank lines and balloon the empty bubble's height.
    ~H"""
    <span id={@id} phx-hook="PetalChatStream" phx-update="ignore" data-event={@event} class={["pc-chat__stream", @class]}><span class="pc-chat__typing" aria-hidden="true"><span></span><span></span><span></span></span><span data-pc-stream-text class="pc-chat__stream-text"></span><span class="pc-chat__caret" aria-hidden="true"></span></span>
    """
  end

  @doc """
  A tool-call card — the chrome around a generative-UI widget.

  This is the "AI Elements" pattern done LiveView-native: the model emits a
  structured tool call (function calling), you map the tool name to one of your
  registered Phoenix components, and render it inside this card. The widget is a
  real LiveView component — it can have its own `phx-click`, forms, streams.

      <.tool_call name="get_weather" status={:complete}>
        <.weather_card city={@args["city"]} temp={@result.temp} />
      </.tool_call>

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
        <span :if={@status == :running} class="pc-chat__tool-spinner" aria-hidden="true"></span>
        <span :if={@status == :complete} class="pc-chat__tool-check" aria-hidden="true">✓</span>
        <span :if={@status == :error} class="pc-chat__tool-error" aria-hidden="true">!</span>
        <span class="pc-chat__tool-name">{@label || @name}</span>
      </div>
      <div :if={@inner_block != []} class="pc-chat__tool-body">{render_slot(@inner_block)}</div>
    </div>
    """
  end

  @doc """
  Renders markdown as sanitized, syntax-highlighted HTML (via MDEx). Use it for
  committed assistant messages so headings, lists, tables and code blocks render
  properly:

      <.chat_message role="assistant"><.markdown content={msg.text} /></.chat_message>

  Output is sanitized server-side — model text is never rendered as live markup.
  """
  attr :content, :string, required: true
  attr :id, :string, default: nil, doc: "pass a unique id to enable per-code-block copy buttons"
  attr :class, :any, default: nil

  def markdown(assigns) do
    assigns = assign(assigns, :html, render_markdown(assigns.content))

    ~H"""
    <div id={@id} phx-hook={@id && "PetalCodeCopy"} class={["pc-chat__markdown", @class]}>{Phoenix.HTML.raw(@html)}</div>
    """
  end

  @doc """
  Markdown with inline widget directives ("MDX for Phoenix").

  The model can drop a widget mid-prose with a fenced block tagged
  ` ```widget:<name> ` containing JSON args. Everything else renders as normal
  markdown (normal code fences like ` ```elixir ` are untouched). You supply a
  `render_widget` function that maps a name + args to a rendered component:

      <.rich_text
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
  attr :render_widget, :any, default: nil, doc: "fn(name :: String.t(), args :: map) -> rendered | nil"
  attr :class, :any, default: nil

  def rich_text(assigns) do
    assigns = assign(assigns, :segments, split_widgets(assigns.content))

    ~H"""
    <div class={["pc-chat__markdown", @class]}>
      <%= for seg <- @segments do %><%= case seg do %><% {:html, html} -> %>{Phoenix.HTML.raw(html)}<% {:widget, name, args} -> %>{@render_widget && @render_widget.(name, args)}<% end %><% end %>
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

  @markdown_opts [
    extension: [strikethrough: true, table: true, autolink: true, tasklist: true],
    syntax_highlight: [formatter: :html_inline],
    sanitize: MDEx.Document.default_sanitize_options()
  ]

  @doc """
  The composer. Wraps a form; pass `phx-submit` (and optionally `phx-change`)
  through the global attrs.

      <.prompt_input phx-submit="send" phx-change="draft" value={@draft} loading={@streaming?} on_stop="stop" />

  While `loading`, the input stays editable (so you can draft your next message)
  and the send button becomes a stop button that pushes `on_stop` — wire it to
  cancel your generation task.
  """
  attr :id, :string, default: "pc-chat-composer"
  attr :name, :string, default: "prompt"
  attr :value, :string, default: ""
  attr :placeholder, :string, default: "Send a message..."
  attr :loading, :boolean, default: false
  attr :on_stop, :string, default: nil, doc: "event pushed when the stop button is clicked while loading"
  attr :submit_label, :string, default: "Send"
  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-submit phx-change phx-target)
  slot :actions, doc: "extra controls left of the send button"

  def prompt_input(assigns) do
    ~H"""
    <form id={@id} phx-hook="PetalChatComposer" class={["pc-chat__composer", @class]} {@rest}>
      <textarea
        name={@name}
        rows="1"
        placeholder={@placeholder}
        autocomplete="off"
        class="pc-chat__composer-input"
      >{@value}</textarea>
      <div :if={@actions != []} class="pc-chat__composer-actions">{render_slot(@actions)}</div>
      <button :if={!@loading} type="submit" class="pc-chat__composer-send">{@submit_label}</button>
      <button
        :if={@loading && @on_stop}
        type="button"
        phx-click={@on_stop}
        aria-label="Stop generating"
        class="pc-chat__composer-stop"
      >
        <span class="pc-chat__stop-icon" aria-hidden="true"></span>
      </button>
      <button :if={@loading && !@on_stop} type="button" disabled class="pc-chat__composer-send">…</button>
    </form>
    """
  end

  @doc """
  A collapsible "thinking" / reasoning block for reasoning-model output. Native
  `<details>`, so no JS.

      <.reasoning>Chain of thought here...</.reasoning>
      <.reasoning label="Thought for 3s" open>...</.reasoning>
  """
  attr :label, :string, default: "Reasoning"
  attr :open, :boolean, default: false
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def reasoning(assigns) do
    ~H"""
    <details class={["pc-chat__reasoning", @class]} open={@open}>
      <summary class="pc-chat__reasoning-summary">{@label}</summary>
      <div class="pc-chat__reasoning-body">{render_slot(@inner_block)}</div>
    </details>
    """
  end

  @doc """
  A row of actions under a message (copy, regenerate, feedback). Compose with
  `copy_button/1` and your own `phx-click` buttons using the `pc-chat__action`
  class.

      <.message_actions>
        <.copy_button id={"copy-\#{@id}"} text={@text} />
        <button class="pc-chat__action" phx-click="regenerate">Regenerate</button>
      </.message_actions>
  """
  attr :class, :any, default: nil
  slot :inner_block, required: true

  def message_actions(assigns) do
    ~H"""
    <div class={["pc-chat__actions", @class]}>{render_slot(@inner_block)}</div>
    """
  end

  @doc """
  A copy-to-clipboard button (via the `PetalCopy` hook). Shows brief "Copied!"
  feedback. Requires a unique `id`.
  """
  attr :id, :string, required: true
  attr :text, :string, required: true, doc: "the text to copy"
  attr :label, :string, default: "Copy"
  attr :class, :any, default: nil

  def copy_button(assigns) do
    ~H"""
    <button
      id={@id}
      type="button"
      phx-hook="PetalCopy"
      data-copy-text={@text}
      data-copied-label="Copied!"
      class={["pc-chat__action", @class]}
    >
      <span data-pc-copy-label>{@label}</span>
    </button>
    """
  end

  @doc """
  Clickable prompt-starter chips for an empty state. Each pushes `on_select`
  with `phx-value-prompt` set to the suggestion.

      <.suggestions items={["Summarise this", "Write tests"]} on_select="suggest" />
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

      <.chat_error on_retry="retry">Something went wrong.</.chat_error>
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
    case MDEx.to_html(content, @markdown_opts) do
      {:ok, html} -> external_links(html)
      {:error, _} -> content |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    end
  end

  # Sanitizer already adds rel="noopener noreferrer"; open links in a new tab so
  # clicking one doesn't navigate away from the chat.
  defp external_links(html), do: String.replace(html, "<a href=", ~s(<a target="_blank" href=))
end
