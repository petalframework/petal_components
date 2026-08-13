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
    * `tool_call/1`      — the tool-call card, from pending through to its result
    * `chat_sources/1`   — the RAG sources row under an answer
    * `citation/1`       — an inline numbered citation chip
    * `message_attachments/1` — images and files inside a sent message
    * `questionnaire/1`  — structured human-in-the-loop input in the thread

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

  ## Answer grounding (RAG citations)

  Sources are plain maps — the host app supplies them, this library only renders
  them. `url` is the only key that really matters; `title`, `snippet`,
  `favicon_url` and `id` are optional and degrade gracefully:

      sources = [
        %{id: "1", url: "https://hexdocs.pm/phoenix_live_view", title: "Phoenix.LiveView",
          snippet: "LiveView provides rich, real-time user experiences...",
          favicon_url: "https://hexdocs.pm/favicon.ico"},
        %{id: "2", url: "https://hexdocs.pm/phoenix", title: "Phoenix"}
      ]

  Prompt the model to cite with **`[^N]` footnote markers** ("cite your sources
  inline as [^1], [^2] matching the numbered context"). Pass `sources` to
  `markdown/1` and every complete marker becomes a chip; markers with no matching
  source stay as plain text:

      <Chat.chat_message role="assistant">
        <Chat.markdown content={msg.text} sources={msg.sources} />
        <Chat.chat_sources sources={msg.sources} />
      </Chat.chat_message>

  A marker resolves to the source whose `id` matches `N` and falls back to the
  Nth source in the list, so an id-less list still works positionally.

  The streaming path takes the same option — `to_html/2` renders the chips into
  the HTML you push at a `format="markdown"` `streaming_text/1`. Half-arrived
  markers (`[^` with no closing bracket yet) are left alone, so nothing flashes
  broken mid-stream:

      socket = push_event(socket, "pc-chat-token", %{
        id: "answer",
        html: PetalComponents.Chat.to_html(buffer, sources: sources)
      })

  ## Tool calls

  `tool_call/1` renders the whole lifecycle a streaming model emits, and the
  state machine is your assigns — there is no client state and no hook. Move
  the card by patching one value as the stream progresses:

      # the model announced the call but the arguments are still arriving
      assign(socket, :call, %{state: :input_streaming, name: "web_search"})

      # arguments complete, the tool is off doing the work
      assign(socket, :call, %{state: :running, name: "web_search", input: args_json})

      # it came back
      assign(socket, :call, %{state: :complete, name: "web_search",
                              input: args_json, output: result_json, duration: "1.2s"})

      <Chat.tool_call
        name={@call.name}
        state={@call.state}
        icon="web_search"
        input={@call[:input]}
        output={@call[:output]}
        duration={@call[:duration]}
      />

  See `tool_call/1` for the compact burst variant and the error/retry shape.

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

  Pass `:sources` to turn `[^N]` footnote markers into inline citation chips as
  the answer streams (see the "Answer grounding" section in the moduledoc):

      PetalComponents.Chat.to_html(buffer, sources: msg.sources)

  ## Options

    * `:sources` — list of source maps. `[^N]` markers matching a source render
      as chips; unmatched and half-streamed markers are left untouched.
  """
  def to_html(content, opts \\ []) do
    content
    |> render_markdown()
    |> apply_citations(Keyword.get(opts, :sources))
  end

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
  A tool-call card — the chrome around a generative-UI widget, and the whole
  lifecycle of the call that produced it.

  This is the "AI Elements" pattern done LiveView-native: the model emits a
  structured tool call (function calling), you map the tool name to one of your
  registered Phoenix components, and render it inside this card. The widget is a
  real LiveView component — it can have its own `phx-click`, forms, streams.

      <Chat.tool_call name="get_weather" state={:complete}>
        <.weather_card city={@args["city"]} temp={@result.temp} />
      </Chat.tool_call>

  ## The lifecycle

  `state` is the source of truth and it is entirely server-driven: your
  LiveView patches the assign as the model's response streams, and each patch
  moves the card. No client state, no hook, no JS.

    * `:pending` — the call is announced, the arguments have not arrived. Tool
      name plus an animated placeholder.
    * `:input_streaming` — the arguments are arriving token by token. Same
      placeholder, now labelled as the incoming input.
    * `:running` — arguments complete, the tool is working. Spinner plus an
      activity line, and `label` carries the live status ("Searching the web").
    * `:complete` — a summary row (check, name, `duration`) with the input and
      output below in expandable panels.
    * `:error` — danger accent, the message inline, and whatever you put in
      `:error_actions` (a retry button) beside it. The input panel stays
      expandable, because the arguments that failed are the useful part.

  The three in-progress states carry `role="status"`, so a screen reader
  announces the card moving through them; the state itself is also spelled out
  in a visually-hidden word next to the tool name, never by colour alone.

      <Chat.tool_call name="web_search" state={:running} icon="web_search" label="Searching the web" />

      <Chat.tool_call
        name="web_search"
        state={:complete}
        icon="web_search"
        duration="1.2s"
        input={~s|{"query":"phoenix liveview streams"}|}
        output={~s|{"results":3}|}
      />

      <Chat.tool_call name="charge_card" state={:error} error="Card token expired before submit.">
        <:error_actions>
          <button type="button" class="pc-chat__action" phx-click="retry_tool">Retry</button>
        </:error_actions>
      </Chat.tool_call>

  `input` and `output` take the JSON string you actually have when streaming
  function calls. It is pretty-printed server-side and rendered as a code
  block; anything that is not valid JSON is shown verbatim rather than
  swallowed. For a rendered result — a chart, a map, a form — keep using the
  default slot, which is always visible; the panels are for inspecting the
  payload, not for hiding your widget.

  ## Compact bursts

  An agent that fires six tools in a row should not produce six cards. `compact`
  renders one dense line per call — state glyph, name, duration — and
  consecutive rows stack into a tight list. Finished rows are the disclosure
  themselves: click (or Enter/Space on the focused row) to reveal the panels.

      <Chat.tool_call :for={call <- @calls} compact
        name={call.name} state={call.state} icon={call.icon}
        duration={call.duration} input={call.input} output={call.output} />

  ## Duration

  `duration` is a string you format — the component never ticks a clock. For a
  live elapsed time while `:running`, compose `PetalComponents.LocalTime` into
  the `label`, or recompute the string on the same timer that drives the state.

  ## Icons

  `icon` takes one of the presets — `"web_search"`, `"code"`, `"database"` — or
  any `"hero-*"` name, which passes straight through to
  `PetalComponents.Icon.icon/1`. For a vendor logo or anything that is not a
  heroicon, use the `:tool_icon` slot. An unrecognised string renders no icon
  rather than raising.
  """
  attr :name, :string, required: true

  attr :state, :atom,
    default: nil,
    values: [nil, :pending, :input_streaming, :running, :complete, :error],
    doc:
      "lifecycle state, server-driven. Defaults to nil, which falls back to the legacy `status` attr — so a card given neither renders exactly as it always has (a completed call). Set this on new code"

  attr :status, :atom,
    default: :complete,
    values: [:running, :complete, :error],
    doc:
      "DEPRECATED, use `state`. Kept so existing call sites render unchanged; consulted only while `state` is nil, and its three values map onto the states of the same name"

  attr :label, :string, default: nil, doc: "human label; defaults to the tool name"

  attr :icon, :string,
    default: nil,
    doc:
      ~s|a preset ("web_search", "code", "database") or any heroicon name ("hero-*"), shown before the tool name. nil shows the state glyph only, and an unrecognised value renders no icon|

  attr :compact, :boolean,
    default: false,
    doc:
      "one dense line per call for multi-tool bursts: state glyph, name, duration. Finished rows expand on click to reveal the panels; consecutive compact calls stack as a list"

  attr :duration, :string,
    default: nil,
    doc:
      ~s|elapsed or total time shown in the header, e.g. "1.2s". You format it — the component never ticks a clock. For a live elapsed while :running, compose `PetalComponents.LocalTime` into the label|

  attr :input, :string,
    default: nil,
    doc:
      "tool arguments as a JSON string; pretty-printed into the expandable Input panel, or shown verbatim if it is not valid JSON. Only rendered once the call has settled (:complete or :error)"

  attr :output, :string,
    default: nil,
    doc:
      "tool result as a JSON string; pretty-printed into the expandable Output panel, or shown verbatim if it is not valid JSON. For a rendered widget use the default slot instead"

  attr :error, :string,
    default: nil,
    doc: "error message rendered inline when the state is :error"

  attr :class, :any, default: nil
  attr :rest, :global

  slot :inner_block, doc: "the rendered widget / tool result. Always visible, never collapsed"

  slot :tool_icon,
    doc:
      "custom icon markup (a vendor logo, an emoji), overriding the `icon` attr. Named `tool_icon` rather than `icon` because a slot cannot share a name with an attr"

  slot :input_panel, doc: "custom Input panel content, overriding the `input` attr"
  slot :output_panel, doc: "custom Output panel content, overriding the `output` attr"

  slot :error_actions,
    doc: "actions rendered beside the error message, e.g. a retry button with phx-click"

  def tool_call(assigns) do
    state = tool_state(assigns)
    input = tool_panel_content(assigns.input_panel, assigns.input)
    output = tool_panel_content(assigns.output_panel, assigns.output)
    settled? = state in [:complete, :error]

    assigns =
      assigns
      |> assign(:state, state)
      |> assign(:input_text, input)
      |> assign(:output_text, output)
      |> assign(:in_progress?, state in [:pending, :input_streaming, :running])
      |> assign(:panels?, settled? and (input != nil or output != nil))
      |> assign(:icon_name, tool_icon_name(assigns.icon))

    # Only a settled row is worth collapsing behind a disclosure: an
    # in-progress compact row stays a plain announced status line.
    assigns =
      assign(
        assigns,
        :revealable?,
        settled? and
          (assigns.panels? or assigns.inner_block != [] or assigns.error_actions != [])
      )

    ~H"""
    <%= if @compact and @revealable? do %>
      <details
        class={["pc-chat__tool", tool_modifier(@state), "pc-chat__tool--compact", @class]}
        {@rest}
      >
        <summary class="pc-chat__tool-header pc-chat__tool-summary">
          <.tool_call_header
            state={@state}
            name={@name}
            label={@label}
            error={@error}
            compact={@compact}
            duration={@duration}
            icon_name={@icon_name}
            tool_icon={@tool_icon}
          />
          <PetalComponents.Icon.icon name="hero-chevron-right" class="pc-chat__tool-chevron" />
        </summary>
        <div class="pc-chat__tool-reveal">
          <.tool_call_body
            state={@state}
            error={@error}
            panels?={@panels?}
            input_text={@input_text}
            output_text={@output_text}
            widget={@inner_block}
            error_actions={@error_actions}
          />
        </div>
      </details>
    <% else %>
      <div
        class={[
          "pc-chat__tool",
          tool_modifier(@state),
          @compact && "pc-chat__tool--compact",
          @class
        ]}
        role={if @in_progress?, do: "status"}
        {@rest}
      >
        <div class="pc-chat__tool-header">
          <.tool_call_header
            state={@state}
            name={@name}
            label={@label}
            error={@error}
            compact={@compact}
            duration={@duration}
            icon_name={@icon_name}
            tool_icon={@tool_icon}
          />
        </div>
        <%!-- Arguments are still arriving: a resting skeleton stands in for
        them, so the card has its final height before the text lands. --%>
        <div :if={@state in [:pending, :input_streaming] and not @compact} class="pc-chat__tool-args">
          <span :if={@state == :input_streaming} class="pc-chat__tool-args-label">Input</span>
          <div class="pc-chat__tool-skeleton" aria-hidden="true">
            <PetalComponents.Skeleton.skeleton
              variant="text"
              animation="shimmer"
              class="h-2.5 w-2/3"
            />
            <PetalComponents.Skeleton.skeleton
              variant="text"
              animation="shimmer"
              class="h-2.5 w-2/5"
            />
          </div>
        </div>
        <.tool_call_body
          state={@state}
          error={@error}
          panels?={@panels?}
          input_text={@input_text}
          output_text={@output_text}
          widget={@inner_block}
          error_actions={@error_actions}
        />
      </div>
    <% end %>
    """
  end

  attr :state, :atom, required: true
  attr :name, :string, required: true
  attr :label, :any, required: true
  attr :error, :any, required: true
  attr :compact, :boolean, required: true
  attr :duration, :any, required: true
  attr :icon_name, :any, required: true
  attr :tool_icon, :any, required: true

  defp tool_call_header(assigns) do
    ~H"""
    <.tool_state_glyph state={@state} />
    <span :if={@tool_icon != []} class="pc-chat__tool-glyph" aria-hidden="true">
      {render_slot(@tool_icon)}
    </span>
    <PetalComponents.Icon.icon
      :if={@tool_icon == [] and @icon_name}
      name={@icon_name}
      class="pc-chat__tool-icon"
    />
    <span class="pc-chat__tool-name">{@label || @name}</span>
    <%!-- Never colour alone: the state is spelled out for screen readers, and
    on a compact error row the message rides along in the row itself so the
    failure is readable without opening anything. --%>
    <span class="sr-only">{tool_state_word(@state)}</span>
    <span :if={@compact and @state == :error and @error} class="pc-chat__tool-error-inline">
      {@error}
    </span>
    <span :if={@duration} class="pc-chat__tool-duration">{@duration}</span>
    """
  end

  attr :state, :atom, required: true
  attr :error, :any, required: true
  attr :panels?, :boolean, required: true
  attr :input_text, :any, required: true
  attr :output_text, :any, required: true
  attr :widget, :any, required: true
  attr :error_actions, :any, required: true

  defp tool_call_body(assigns) do
    ~H"""
    <div :if={@widget != []} class="pc-chat__tool-body">{render_slot(@widget)}</div>
    <div
      :if={@state == :error and (@error || @error_actions != [])}
      class="pc-chat__tool-error-row"
    >
      <p :if={@error} class="pc-chat__tool-error-message">{@error}</p>
      <div :if={@error_actions != []} class="pc-chat__tool-error-actions">
        {render_slot(@error_actions)}
      </div>
    </div>
    <%!-- Payload panels only once the call has settled: there is nothing
    honest to show while the arguments are still arriving. --%>
    <div :if={@panels?} class="pc-chat__tool-panels">
      <.tool_panel :if={@input_text} label="Input" content={@input_text} />
      <.tool_panel :if={@output_text} label="Output" content={@output_text} />
    </div>
    """
  end

  attr :label, :string, required: true
  attr :content, :any, required: true

  defp tool_panel(assigns) do
    ~H"""
    <details class="pc-chat__tool-panel">
      <summary class="pc-chat__tool-panel-summary">
        <PetalComponents.Icon.icon name="hero-chevron-right" class="pc-chat__tool-chevron" />
        {@label}
      </summary>
      <div class="pc-chat__tool-panel-body">
        <%= if is_binary(@content) do %>
          <pre class="pc-chat__tool-code"><code>{@content}</code></pre>
        <% else %>
          {render_slot(@content)}
        <% end %>
      </div>
    </details>
    """
  end

  attr :state, :atom, required: true

  defp tool_state_glyph(%{state: :running} = assigns),
    do: ~H|<span class="pc-chat__tool-spinner" aria-hidden="true"></span>|

  defp tool_state_glyph(%{state: :error} = assigns),
    do: ~H|<span class="pc-chat__tool-error" aria-hidden="true">!</span>|

  # Pending and streaming-input reuse the thread's own typing dots rather than
  # inventing a second waiting idiom.
  defp tool_state_glyph(%{state: state} = assigns) when state in [:pending, :input_streaming],
    do:
      ~H|<span class="pc-chat__typing pc-chat__tool-typing" aria-hidden="true"><span></span><span></span><span></span></span>|

  defp tool_state_glyph(assigns),
    do: ~H|<span class="pc-chat__tool-check" aria-hidden="true">✓</span>|

  # `state` wins; `status` is only consulted while it is nil, which keeps the
  # pre-state call sites (and their default `status={:complete}`) rendering
  # exactly what they always did.
  defp tool_state(%{state: nil, status: status}), do: status
  defp tool_state(%{state: state}), do: state

  defp tool_modifier(state), do: "pc-chat__tool--" <> String.replace(to_string(state), "_", "-")

  defp tool_state_word(:pending), do: "Pending"
  defp tool_state_word(:input_streaming), do: "Receiving input"
  defp tool_state_word(:running), do: "Running"
  defp tool_state_word(:error), do: "Failed"
  defp tool_state_word(_), do: "Complete"

  # A slot beats the attr; the attr is JSON we pretty-print for reading.
  defp tool_panel_content([_ | _] = slot, _json), do: slot
  defp tool_panel_content(_slot, json), do: pretty_json(json)

  defp pretty_json(nil), do: nil
  defp pretty_json(""), do: nil

  defp pretty_json(json) when is_binary(json) do
    case Jason.decode(json) do
      {:ok, _} -> Jason.Formatter.pretty_print(json)
      {:error, _} -> json
    end
  end

  defp pretty_json(other), do: other

  # Kept in one place so adding a preset is a one-line change. Anything already
  # namespaced as a heroicon passes through untouched; anything else is dropped
  # rather than handed to icon/1, which would raise on an unknown name.
  defp tool_icon_name(nil), do: nil
  defp tool_icon_name("web_search"), do: "hero-magnifying-glass"
  defp tool_icon_name("code"), do: "hero-code-bracket"
  defp tool_icon_name("database"), do: "hero-circle-stack"
  defp tool_icon_name("hero-" <> _ = name), do: name
  defp tool_icon_name(_), do: nil

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

  attr :sources, :list,
    default: nil,
    doc:
      "when set, complete `[^N]` markers in the content render as inline citation chips for the matching source (by `id`, falling back to the Nth source). Unmatched markers stay as plain text"

  attr :class, :any, default: nil

  def markdown(assigns) do
    assigns =
      assign(assigns, :html, apply_citations(render_markdown(assigns.content), assigns.sources))

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

  ## Attachments

  Pass an `%Phoenix.LiveView.UploadConfig{}` from `allow_upload/3` and the
  composer grows a paperclip trigger, a chip strip for the pending entries,
  drag-onto-the-composer, paste-an-image, and inline upload errors. It is
  ordinary LiveView uploads — this component only renders them:

      def mount(_, _, socket) do
        {:ok, allow_upload(socket, :attachments, accept: ~w(.png .jpg .jpeg .pdf),
                           max_entries: 4, max_file_size: 5_000_000)}
      end

      def handle_event("validate", _params, socket), do: {:noreply, socket}

      def handle_event("cancel-upload", %{"ref" => ref}, socket) do
        {:noreply, cancel_upload(socket, :attachments, ref)}
      end

      def handle_event("send", %{"prompt" => text}, socket) do
        files = consume_uploaded_entries(socket, :attachments, fn %{path: path}, entry ->
          {:ok, store(path, entry)}
        end)
        {:noreply, send_message(socket, text, files)}
      end

      <Chat.prompt_input
        phx-submit="send"
        phx-change="validate"
        upload={@uploads.attachments}
        on_cancel_upload="cancel-upload"
        accept_hint="Images and PDFs up to 5 MB"
      />

  `phx-change` is required for uploads to progress — LiveView needs a change
  event on the form. With no `upload` the composer renders exactly as it always
  has.
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

  attr :upload, :any,
    default: nil,
    doc:
      "a %Phoenix.LiveView.UploadConfig{} from allow_upload/3. When set the composer renders a paperclip trigger wrapping a visually hidden live_file_input, attachment chips for @upload.entries, becomes a phx-drop-target, and accepts pasted images"

  attr :on_cancel_upload, :string,
    default: "cancel-upload",
    doc:
      "event pushed by a chip's remove button, with phx-value-ref set to the entry ref (wire it to cancel_upload/3)"

  attr :accept_hint, :string,
    default: nil,
    doc:
      ~s|human-readable hint of accepted types and size (e.g. "Images and PDFs up to 10 MB"), used as the paperclip button's title and accessible description|

  attr :class, :any, default: nil
  attr :rest, :global, include: ~w(phx-submit phx-change phx-target)
  slot :actions, doc: "extra controls left of the send button"

  def prompt_input(assigns) do
    assigns = assign_new(assigns, :id, fn -> "pc-chat-composer-#{Ecto.UUID.generate()}" end)

    ~H"""
    <form
      id={@id}
      phx-hook="PetalChatComposer"
      phx-drop-target={@upload && @upload.ref}
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
      <ul
        :if={@upload && @upload.entries != []}
        role="list"
        class="pc-chat__composer-attachments"
      >
        <.attachment_chip
          :for={entry <- @upload.entries}
          entry={entry}
          upload={@upload}
          on_cancel_upload={@on_cancel_upload}
        />
      </ul>
      <div class="pc-chat__composer-row">
        <label :if={@upload} class="pc-chat__composer-attach" title={@accept_hint}>
          <PetalComponents.Icon.icon name="hero-paper-clip" class="pc-chat__composer-attach-icon" />
          <.live_file_input
            upload={@upload}
            class="sr-only"
            aria-label="Attach files"
            aria-description={@accept_hint}
          />
        </label>
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
      <div :if={@upload && upload_error_messages(@upload) != []} class="pc-chat__composer-errors">
        <p
          :for={message <- upload_error_messages(@upload)}
          role="alert"
          class="pc-chat__composer-error"
        >
          <PetalComponents.Icon.icon
            name="hero-exclamation-circle"
            class="pc-chat__composer-error-icon"
          />
          {message}
        </p>
      </div>
    </form>
    """
  end

  attr :entry, :any, required: true
  attr :upload, :any, required: true
  attr :on_cancel_upload, :string, required: true

  defp attachment_chip(assigns) do
    assigns = assign(assigns, :image?, image_entry?(assigns.entry))

    ~H"""
    <li class={[
      "pc-chat__attachment",
      if(@image?, do: "pc-chat__attachment--image", else: "pc-chat__attachment--file")
    ]}>
      <.live_img_preview :if={@image?} entry={@entry} class="pc-chat__attachment-thumb" />
      <PetalComponents.Icon.icon
        :if={!@image?}
        name="hero-document"
        class="pc-chat__attachment-icon"
      />
      <span :if={!@image?} class="pc-chat__attachment-meta">
        <span class="pc-chat__attachment-name">{@entry.client_name}</span>
        <span class="pc-chat__attachment-size">{format_bytes(@entry.client_size)}</span>
      </span>
      <span
        :if={@entry.progress < 100}
        role="progressbar"
        aria-valuenow={@entry.progress}
        aria-valuemin="0"
        aria-valuemax="100"
        aria-label={"Uploading #{@entry.client_name}"}
        data-progress={@entry.progress}
        style={"--pc-attachment-progress: #{@entry.progress}"}
        class="pc-chat__attachment-progress"
      ></span>
      <button
        type="button"
        phx-click={@on_cancel_upload}
        phx-value-ref={@entry.ref}
        aria-label={"Remove #{@entry.client_name}"}
        class="pc-chat__attachment-remove"
      >
        <PetalComponents.Icon.icon name="hero-x-mark" class="pc-chat__attachment-remove-icon" />
      </button>
    </li>
    """
  end

  @doc """
  Attachments rendered inside a sent message — the images and files that went
  along with the text. Drop it in a `chat_message/1` body, before or after the
  prose:

      <Chat.chat_message role="user">
        <Chat.message_attachments attachments={msg.attachments} />
        {msg.text}
      </Chat.chat_message>

  Images render as a thumbnail grid (one image goes large, two or more tile),
  files as compact download rows. A mixed list puts the images first.
  """
  attr :attachments, :list,
    required: true,
    doc:
      "list of maps: %{kind: :image | :file, url, name, size}. :kind picks the rendering, :size is bytes and is formatted for display or omitted when nil. String or atom keys both accepted"

  attr :class, :any, default: nil
  attr :rest, :global

  def message_attachments(assigns) do
    items = normalize_attachments(assigns.attachments)
    {images, files} = Enum.split_with(items, &(&1.kind == :image))

    assigns = assigns |> assign(:images, images) |> assign(:files, files)

    ~H"""
    <div :if={@images != [] or @files != []} class={["pc-chat__message-attachments", @class]} {@rest}>
      <div
        :if={@images != []}
        class={[
          "pc-chat__message-attachments-grid",
          length(@images) > 1 && "pc-chat__message-attachments-grid--multi"
        ]}
      >
        <a
          :for={image <- @images}
          href={image.url}
          target="_blank"
          rel="noopener noreferrer"
          class="pc-chat__attachment-image"
        >
          <img src={image.url} alt={image.name} loading="lazy" />
        </a>
      </div>
      <a
        :for={file <- @files}
        href={file.url}
        download
        class="pc-chat__attachment-row"
      >
        <PetalComponents.Icon.icon name="hero-document" class="pc-chat__attachment-icon" />
        <span class="pc-chat__attachment-name">{file.name}</span>
        <span :if={file.size} class="pc-chat__attachment-size">{format_bytes(file.size)}</span>
      </a>
    </div>
    """
  end

  @doc """
  Structured human-in-the-loop input, rendered inside the conversation. The
  model (via your app) emits a question spec; this renders it as a form in the
  transcript, and once the app has the answer it renders back as a quiet
  summary so the transcript stays honest about what was asked and answered.

  Server-driven end to end — a plain `phx-submit`, no client state, no client
  form engine.

      <Chat.chat_message role="assistant">
        <Chat.questionnaire spec={@question} resolved={@answers} allow_skip />
      </Chat.chat_message>

  ## The spec

      %{
        id: "q-framework",
        title: "Which framework are you targeting?",
        description: "This picks the generators I'll reach for.",
        fields: [
          %{id: "framework", type: :single_select, label: "Framework", required: true,
            options: [
              %{value: "phoenix", label: "Phoenix", description: "Elixir, LiveView"},
              %{value: "rails", label: "Rails", description: "Ruby, Hotwire"}
            ]},
          %{id: "features", type: :multi_select, label: "Features",
            options: [%{value: "auth", label: "Auth"}, %{value: "billing", label: "Billing"}]},
          %{id: "team", type: :text, label: "Team name", placeholder: "Acme"},
          %{id: "confidence", type: :scale, label: "How sure are you?",
            min_label: "Not sure", max_label: "Certain", required: true}
        ]
      }

  String and atom keys are both accepted. `:single_select` renders radio-cards
  when any option carries a `description`, plain radios otherwise — override
  per field with `style: "cards"` or `style: "buttons"`.

  ## The params you get back

  Inputs are named `answers[<field_id>]` (`answers[<field_id>][]` for
  multi-select), plus a hidden `spec_id` echoing the spec:

      def handle_event("questionnaire_submit", %{"spec_id" => id, "answers" => answers}, socket) do
        # %{"framework" => "phoenix", "features" => ["auth"], "confidence" => "4"}
        {:noreply, socket |> answer(id, answers) |> ask_the_model(answers)}
      end

      def handle_event("questionnaire_skip", %{"id" => id}, socket) do
        {:noreply, assign(socket, :answers, :skipped)}
      end

  Required fields use the native `required` attribute — server-side validation
  stays in your app. The exception is `:multi_select`: a native `required`
  checkbox demands *that* box specifically, so a required multi-select carries
  the asterisk and the "(required)" in its legend but is not browser-enforced.
  Validate it server-side.

  ## Resolving it

  Pass the answer map back as `resolved` and the form is replaced by chips;
  pass `:skipped` for the skipped line. Nothing focusable is left behind — no
  disabled form pretending to still be a control.
  """
  attr :spec, :map,
    required: true,
    doc:
      "the question spec: %{id, title, description, fields: [...]}. `id` namespaces the ids inside, so give two questionnaires on one page two ids; `title` labels the form and should be set. Each field is %{id, type, label, required, options, placeholder, min_label, max_label, style}, where type is :single_select | :multi_select | :text | :scale. `required` is browser-enforced everywhere except :multi_select, where it is advisory (marker plus announcement, your server validates). String or atom keys both accepted"

  attr :resolved, :any,
    default: nil,
    doc:
      "nil while pending. A map of answers keyed by field id renders the resolved summary; the atom :skipped renders the skipped state"

  attr :on_submit, :string,
    default: "questionnaire_submit",
    doc: "phx-submit event name posted to the parent LiveView"

  attr :allow_skip, :boolean,
    default: false,
    doc: "renders a Skip button that posts on_skip with the spec id"

  attr :on_skip, :string,
    default: "questionnaire_skip",
    doc: "phx-click event for the skip button, with phx-value-id set to the spec id"

  attr :submitting, :boolean,
    default: false,
    doc:
      "disables every input and both buttons and shows a spinner while the app forwards the answer"

  attr :submit_label, :string, default: "Submit", doc: "text on the submit button"
  attr :class, :any, default: nil
  attr :rest, :global

  def questionnaire(assigns) do
    spec = normalize_spec(assigns.spec)

    assigns =
      assigns
      |> assign(:spec, spec)
      |> assign(:title_id, "#{spec.id}-title")
      |> assign(:answers, resolved_answers(spec, assigns.resolved))

    ~H"""
    <div
      class={[
        "pc-questionnaire",
        @resolved == :skipped && "pc-questionnaire--skipped",
        is_map(@resolved) && "pc-questionnaire--resolved",
        @class
      ]}
      {@rest}
    >
      <%!-- A spec with no title gets no empty heading, and nothing points
      aria-labelledby at it. --%>
      <div :if={@spec.title || @spec.description} class="pc-questionnaire__header">
        <h3 :if={@spec.title} id={@title_id} class="pc-questionnaire__title">{@spec.title}</h3>
        <p :if={@spec.description} class="pc-questionnaire__description">{@spec.description}</p>
      </div>

      <%= cond do %>
        <% @resolved == :skipped -> %>
          <p class="pc-questionnaire__skipped-note">Skipped</p>
        <% is_map(@resolved) -> %>
          <dl class="pc-questionnaire__summary">
            <div :for={{field, chips} <- @answers} class="pc-questionnaire__answer">
              <dt class="pc-questionnaire__answer-label">{field.label}</dt>
              <dd class="pc-questionnaire__answer-value">
                <span :for={chip <- chips} class="pc-questionnaire__chip">{chip}</span>
              </dd>
            </div>
          </dl>
        <% true -> %>
          <form
            phx-submit={@on_submit}
            aria-labelledby={@spec.title && @title_id}
            class="pc-questionnaire__form"
          >
            <input type="hidden" name="spec_id" value={@spec.id} />
            <.questionnaire_field
              :for={field <- @spec.fields}
              field={field}
              spec_id={@spec.id}
              submitting={@submitting}
            />
            <div class="pc-questionnaire__actions">
              <button
                type="submit"
                disabled={@submitting}
                class="pc-questionnaire__submit"
              >
                <span :if={@submitting} role="status" class="pc-questionnaire__spinner-wrap">
                  <span class="pc-questionnaire__spinner" aria-hidden="true"></span>
                  <span class="sr-only">Submitting</span>
                </span>
                {@submit_label}
              </button>
              <button
                :if={@allow_skip}
                type="button"
                phx-click={@on_skip}
                phx-value-id={@spec.id}
                disabled={@submitting}
                class="pc-questionnaire__skip"
              >
                Skip
              </button>
            </div>
          </form>
      <% end %>
    </div>
    """
  end

  attr :field, :map, required: true
  attr :spec_id, :string, required: true
  attr :submitting, :boolean, required: true

  defp questionnaire_field(assigns) do
    assigns =
      assigns
      |> assign(:name, "answers[#{assigns.field.id}]")
      # Namespaced by the spec, so the same question rendered twice on a page
      # (a flow card and a demo of it, say) doesn't collide on input ids and
      # send a label's click to the other instance.
      |> assign(:field_id, "#{assigns.spec_id}-#{assigns.field.id}")
      |> assign(:legend, questionnaire_legend(assigns.field))

    ~H"""
    <fieldset class={["pc-questionnaire__field", "pc-questionnaire__field--#{@field.type}"]}>
      <legend class="sr-only">{@legend}</legend>
      <%= case @field.type do %>
        <% :single_select -> %>
          <PetalComponents.Field.field
            :if={questionnaire_style(@field) == "cards"}
            type="radio-card"
            id={@field_id}
            name={@name}
            label={@field.label}
            options={@field.options}
            required={@field.required}
            disabled={@submitting}
            group_layout="col"
            no_margin
          />
          <PetalComponents.Field.field
            :if={questionnaire_style(@field) != "cards"}
            type="radio-group"
            id={@field_id}
            name={@name}
            label={@field.label}
            options={option_tuples(@field.options)}
            required={@field.required}
            disabled={@submitting}
            group_layout="col"
            no_margin
          />
        <% :multi_select -> %>
          <PetalComponents.Field.field
            type="checkbox-group"
            id={@field_id}
            name={@name}
            label={@field.label}
            options={option_tuples(@field.options)}
            required={@field.required}
            disabled={@submitting}
            group_layout="col"
            no_margin
          />
        <% :text -> %>
          <PetalComponents.Field.field
            type="text"
            id={@field_id}
            name={@name}
            label={@field.label}
            placeholder={@field.placeholder}
            required={@field.required}
            disabled={@submitting}
            no_margin
          />
        <% :scale -> %>
          <.questionnaire_scale
            field={@field}
            name={@name}
            spec_id={@spec_id}
            submitting={@submitting}
          />
      <% end %>
    </fieldset>
    """
  end

  attr :field, :map, required: true
  attr :name, :string, required: true
  attr :spec_id, :string, required: true
  attr :submitting, :boolean, required: true

  defp questionnaire_scale(assigns) do
    assigns = assign(assigns, :caption_id, "#{assigns.spec_id}-#{assigns.field.id}-captions")

    ~H"""
    <span class={["pc-label", @field.required && "pc-label--required"]}>{@field.label}</span>
    <div class="pc-questionnaire__scale">
      <label :for={value <- 1..5} class="pc-questionnaire__scale-step">
        <input
          type="radio"
          name={@name}
          value={value}
          required={@field.required}
          disabled={@submitting}
          aria-describedby={(@field.min_label || @field.max_label) && @caption_id}
          class="sr-only pc-questionnaire__scale-input"
        />
        <span class="pc-questionnaire__scale-number">{value}</span>
      </label>
    </div>
    <div
      :if={@field.min_label || @field.max_label}
      id={@caption_id}
      class="pc-questionnaire__scale-captions"
    >
      <span>{@field.min_label}</span>
      <span>{@field.max_label}</span>
    </div>
    """
  end

  # -- questionnaire plumbing ------------------------------------------------

  defp normalize_spec(spec) when is_map(spec) do
    %{
      id: to_string(source_key(spec, :id) || "questionnaire"),
      title: source_key(spec, :title),
      description: source_key(spec, :description),
      fields: spec |> source_key(:fields) |> List.wrap() |> Enum.map(&normalize_spec_field/1)
    }
  end

  defp normalize_spec_field(field) do
    %{
      id: to_string(source_key(field, :id)),
      type: normalize_field_type(source_key(field, :type)),
      label: source_key(field, :label),
      required: source_key(field, :required) == true,
      placeholder: source_key(field, :placeholder),
      style: source_key(field, :style),
      min_label: source_key(field, :min_label),
      max_label: source_key(field, :max_label),
      options: field |> source_key(:options) |> List.wrap() |> Enum.map(&normalize_option/1)
    }
  end

  defp normalize_field_type(type) when type in [:single_select, "single_select"],
    do: :single_select

  defp normalize_field_type(type) when type in [:multi_select, "multi_select"], do: :multi_select
  defp normalize_field_type(type) when type in [:scale, "scale"], do: :scale
  defp normalize_field_type(_), do: :text

  defp normalize_option(option) when is_map(option) do
    %{
      value: to_string(source_key(option, :value)),
      label: source_key(option, :label) || to_string(source_key(option, :value)),
      description: source_key(option, :description)
    }
  end

  # Cards when the author asked for them, or when any option carries a
  # description worth showing. Plain radios otherwise.
  defp questionnaire_style(%{style: style}) when style in ["cards", "buttons"], do: style

  defp questionnaire_style(%{options: options}) do
    if Enum.any?(options, & &1.description), do: "cards", else: "buttons"
  end

  defp questionnaire_legend(%{label: label, required: true}), do: "#{label} (required)"
  defp questionnaire_legend(%{label: label}), do: label

  defp option_tuples(options), do: Enum.map(options, &{&1.label, &1.value})

  # [{field, [chip, ...]}] for every field the answer map actually answered.
  defp resolved_answers(_spec, resolved) when not is_map(resolved), do: []

  defp resolved_answers(spec, resolved) do
    spec.fields
    |> Enum.map(fn field -> {field, answer_chips(field, answer_for(resolved, field.id))} end)
    |> Enum.reject(fn {_field, chips} -> chips == [] end)
  end

  # Field ids come off a model-emitted spec, so String.to_atom/1 here would be
  # an atom-table leak by design. Scan the map instead - answer maps are a
  # handful of keys, and this reads atom and string keys the same way.
  defp answer_for(resolved, id) do
    case Map.fetch(resolved, id) do
      {:ok, value} ->
        value

      :error ->
        case Enum.find(resolved, fn {key, _} -> is_atom(key) and Atom.to_string(key) == id end) do
          {_key, value} -> value
          nil -> nil
        end
    end
  end

  defp answer_chips(_field, nil), do: []
  defp answer_chips(_field, ""), do: []

  defp answer_chips(field, values) when is_list(values),
    do: Enum.flat_map(values, &answer_chips(field, &1))

  defp answer_chips(%{type: :scale} = field, value) do
    caption =
      case to_string(value) do
        "1" -> field.min_label
        "5" -> field.max_label
        _ -> nil
      end

    [if(caption, do: "#{value} · #{caption}", else: to_string(value))]
  end

  defp answer_chips(field, value) do
    value = to_string(value)

    case Enum.find(field.options, &(&1.value == value)) do
      nil -> [value]
      option -> [option.label]
    end
  end

  # -- attachment plumbing ---------------------------------------------------

  defp image_entry?(%{client_type: "image/" <> _}), do: true
  defp image_entry?(_), do: false

  defp normalize_attachments(attachments) when is_list(attachments) do
    Enum.map(attachments, fn attachment ->
      %{
        kind: if(source_key(attachment, :kind) in [:image, "image"], do: :image, else: :file),
        url: source_key(attachment, :url),
        name: source_key(attachment, :name),
        size: source_key(attachment, :size)
      }
    end)
  end

  defp normalize_attachments(_), do: []

  # Config-level errors first (too_many_files and friends), then per-entry ones
  # named with the file they belong to, so "too large" says which file.
  defp upload_error_messages(upload) do
    config_errors = Enum.map(upload_errors(upload), &upload_error_copy/1)

    entry_errors =
      Enum.flat_map(upload.entries, fn entry ->
        Enum.map(upload_errors(upload, entry), fn error ->
          "#{entry.client_name}: #{upload_error_copy(error)}"
        end)
      end)

    config_errors ++ entry_errors
  end

  defp upload_error_copy(:too_large), do: "This file is too large."
  defp upload_error_copy(:not_accepted), do: "This file type isn't accepted."
  defp upload_error_copy(:too_many_files), do: "Too many files selected."

  defp upload_error_copy(:external_client_failure),
    do: "Something went wrong uploading this file."

  defp upload_error_copy(other), do: "Upload failed (#{inspect(other)})."

  defp format_bytes(nil), do: nil
  defp format_bytes(bytes) when bytes < 1_000, do: "#{bytes} B"
  defp format_bytes(bytes) when bytes < 1_000_000, do: "#{Float.round(bytes / 1_000, 1)} KB"

  defp format_bytes(bytes) when bytes < 1_000_000_000,
    do: "#{Float.round(bytes / 1_000_000, 1)} MB"

  defp format_bytes(bytes), do: "#{Float.round(bytes / 1_000_000_000, 1)} GB"

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

  @doc """
  An inline numbered citation chip — the superscript marker that grounds a
  sentence in a source. Hovering or focusing it reveals a small preview card
  (title, domain, snippet); activating it opens the source in a new tab.

  `markdown/1` and `to_html/2` mint these for you from `[^N]` markers, so you
  rarely call it directly. Reach for it when you are assembling prose yourself:

      Phoenix ships with LiveView <Chat.citation index={1} source={@source} />
  """
  attr :index, :integer, required: true, doc: "1-based citation number shown in the chip"

  attr :source, :map,
    required: true,
    doc:
      "the source map this chip points at: %{url, title, snippet, favicon_url}; every key but `url` is optional"

  attr :class, :any, default: nil

  def citation(assigns) do
    assigns =
      assign(assigns, :html, citation_html(assigns.index, normalize_source(assigns.source)))

    ~H"""
    <span class={@class && ["pc-chat__citation-outer", @class]}>{Phoenix.HTML.raw(@html)}</span>
    """
  end

  @doc """
  The sources row under a grounded answer. Collapsed it reads "4 sources" with a
  stacked-favicon cluster; open it lists each source with its favicon, title,
  domain and snippet. Native `<details>`, so no JS.

      <Chat.chat_sources sources={@sources} />
      <Chat.chat_sources sources={@sources} expanded max_visible={3} />

  Sources are deduped by URL before render (the same page cited twice is one
  row), and a nil or empty list renders nothing at all — no empty shell.
  """
  attr :sources, :list,
    required: true,
    doc:
      "list of source maps: %{id, url, title, snippet, favicon_url}; snippet and favicon_url optional. Deduped by URL before render"

  attr :expanded, :boolean,
    default: false,
    doc: "render the list open instead of the collapsed 'N sources' row"

  attr :max_visible, :integer,
    default: 5,
    doc: "sources shown when expanded before a 'Show all (N)' control reveals the rest"

  attr :label, :string,
    default: nil,
    doc: "override the collapsed row label; defaults to '{count} sources' / '1 source'"

  attr :class, :any, default: nil
  attr :rest, :global

  def chat_sources(assigns) do
    items = assigns.sources |> normalize_sources() |> dedupe_sources()

    assigns =
      assigns
      |> assign(:items, items)
      |> assign(:visible, Enum.take(items, max(assigns.max_visible, 0)))
      |> assign(:overflow, Enum.drop(items, max(assigns.max_visible, 0)))
      |> assign(:count, length(items))

    ~H"""
    <details :if={@items != []} class={["pc-chat__sources", @class]} open={@expanded} {@rest}>
      <summary class="pc-chat__sources-row">
        <span class="pc-chat__sources-favicons" aria-hidden="true">
          <.source_favicon :for={source <- Enum.take(@items, 3)} source={source} />
        </span>
        <span class="pc-chat__sources-label">
          {@label || if(@count == 1, do: "1 source", else: "#{@count} sources")}
        </span>
        <PetalComponents.Icon.icon name="hero-chevron-right" class="pc-chat__sources-chevron" />
      </summary>
      <ul class="pc-chat__sources-list" role="list">
        <.source_row :for={source <- @visible} source={source} />
      </ul>
      <details :if={@overflow != []} class="pc-chat__sources-more">
        <summary class="pc-chat__sources-more-summary">Show all ({@count})</summary>
        <ul class="pc-chat__sources-list" role="list">
          <.source_row :for={source <- @overflow} source={source} />
        </ul>
      </details>
    </details>
    """
  end

  attr :source, :map, required: true

  defp source_row(assigns) do
    ~H"""
    <li class="pc-chat__source">
      <a
        href={@source.url}
        target="_blank"
        rel="noopener noreferrer"
        class="pc-chat__source-link"
      >
        <.source_favicon source={@source} />
        <span class="pc-chat__source-text">
          <span class="pc-chat__source-title">{@source.title || @source.url}</span>
          <span :if={source_domain(@source)} class="pc-chat__source-domain">
            {source_domain(@source)}
          </span>
          <span :if={@source.snippet} class="pc-chat__source-snippet">{@source.snippet}</span>
        </span>
      </a>
    </li>
    """
  end

  attr :source, :map, required: true

  defp source_favicon(assigns) do
    ~H"""
    <img
      :if={@source.favicon_url}
      src={@source.favicon_url}
      alt=""
      aria-hidden="true"
      loading="lazy"
      class="pc-chat__source-favicon"
    />
    <span
      :if={!@source.favicon_url}
      aria-hidden="true"
      class="pc-chat__source-favicon pc-chat__source-favicon--letter"
    >
      {source_initial(@source)}
    </span>
    """
  end

  # -- citation plumbing -----------------------------------------------------

  # Only complete markers match, so a half-streamed "[^" never flashes a broken
  # chip; it simply stays as text until the closing bracket arrives.
  @citation_marker ~r/\[\^(\d+)\]/
  @html_tag ~r/<[^>]*>/

  defp apply_citations(html, sources) when is_binary(html) do
    case citation_lookup(sources) do
      lookup when map_size(lookup) == 0 -> html
      lookup -> splice_citations(html, lookup)
    end
  end

  # Walk the sanitized HTML as a tag/text token stream and rewrite markers in
  # text nodes only: never inside an attribute, never inside <pre>/<code>. The
  # chip markup is minted here from the numeric index plus escaped source
  # fields, so model-controlled text can never reach the page as live markup.
  defp splice_citations(html, lookup) do
    @html_tag
    |> Regex.split(html, include_captures: true)
    |> Enum.reduce({[], 0}, fn part, {acc, depth} ->
      cond do
        String.starts_with?(part, "<") -> {[part | acc], code_depth(part, depth)}
        depth > 0 -> {[part | acc], depth}
        true -> {[replace_markers(part, lookup) | acc], depth}
      end
    end)
    |> elem(0)
    |> Enum.reverse()
    |> IO.iodata_to_binary()
  end

  defp code_depth(tag, depth) do
    cond do
      Regex.match?(~r{^</(?:pre|code)\s*>$}i, tag) -> max(depth - 1, 0)
      Regex.match?(~r{^<(?:pre|code)(?:\s[^>]*)?>$}i, tag) -> depth + 1
      true -> depth
    end
  end

  defp replace_markers(text, lookup) do
    Regex.replace(@citation_marker, text, fn marker, number ->
      case Map.fetch(lookup, number) do
        {:ok, source} -> citation_html(String.to_integer(number), source)
        :error -> marker
      end
    end)
  end

  defp citation_lookup(sources) do
    normalized = normalize_sources(sources)

    by_position =
      normalized
      |> Enum.with_index(1)
      |> Map.new(fn {source, index} -> {Integer.to_string(index), source} end)

    by_id =
      Enum.reduce(normalized, %{}, fn
        %{id: nil}, acc -> acc
        %{id: id} = source, acc -> Map.put_new(acc, to_string(id), source)
      end)

    Map.merge(by_position, by_id)
  end

  defp citation_html(index, source) do
    title = source.title || source_domain(source) || "Source #{index}"
    domain = source_domain(source)

    ~s(<span class="pc-chat__citation-wrap"><a class="pc-chat__citation" href="#{esc(source.url)}") <>
      ~s( target="_blank" rel="noopener noreferrer" aria-label="#{esc("Source #{index}: #{title}")}">) <>
      ~s(<sup class="pc-chat__citation-num">#{index}</sup></a>) <>
      ~s(<span class="pc-chat__citation-card" aria-hidden="true">) <>
      citation_card_favicon(source) <>
      ~s(<span class="pc-chat__citation-card-title">#{esc(title)}</span>) <>
      if(domain,
        do: ~s(<span class="pc-chat__citation-card-domain">#{esc(domain)}</span>),
        else: ""
      ) <>
      if(source.snippet,
        do: ~s(<span class="pc-chat__citation-card-snippet">#{esc(source.snippet)}</span>),
        else: ""
      ) <> ~s(</span></span>)
  end

  defp citation_card_favicon(%{favicon_url: nil} = source) do
    ~s(<span class="pc-chat__source-favicon pc-chat__source-favicon--letter" aria-hidden="true">) <>
      esc(source_initial(source)) <> ~s(</span>)
  end

  defp citation_card_favicon(source) do
    ~s(<img class="pc-chat__source-favicon" src="#{esc(source.favicon_url)}" alt="") <>
      ~s( aria-hidden="true" loading="lazy" />)
  end

  defp esc(nil), do: ""

  defp esc(value),
    do: value |> to_string() |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()

  defp normalize_sources(sources) when is_list(sources),
    do: Enum.map(sources, &normalize_source/1)

  defp normalize_sources(_), do: []

  defp normalize_source(source) when is_map(source) do
    %{
      id: source_key(source, :id),
      url: source_key(source, :url),
      title: source_key(source, :title),
      snippet: source_key(source, :snippet),
      favicon_url: source_key(source, :favicon_url)
    }
  end

  defp source_key(source, key) do
    case Map.fetch(source, key) do
      {:ok, value} -> value
      :error -> Map.get(source, Atom.to_string(key))
    end
  end

  defp dedupe_sources(sources), do: Enum.uniq_by(sources, & &1.url)

  defp source_domain(%{url: url}) when is_binary(url) do
    case URI.parse(url) do
      %URI{host: host} when is_binary(host) -> String.replace_prefix(host, "www.", "")
      _ -> nil
    end
  end

  defp source_domain(_), do: nil

  defp source_initial(source) do
    (source.title || source_domain(source) || "?")
    |> String.trim()
    |> String.first()
    |> Kernel.||("?")
    |> String.upcase()
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
