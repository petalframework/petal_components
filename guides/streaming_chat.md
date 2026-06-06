# Build a streaming AI chat

The `PetalComponents.Chat` family lets you build a streaming chat UI — the kind
you'd reach for assistant-ui or Vercel AI Elements for in React — without a
client AI SDK. Tokens stream over the LiveView socket you already have.

This guide builds a working chat: a thread, streaming assistant replies, and a
composer. It's provider-agnostic — wherever you see `MyApp.LLM.stream/2`, plug
in your own OpenAI/Anthropic/Gemini client.

## Prerequisites

- petal_components installed (see the README), including the JS hooks step:

  ```js
  import PetalComponents from "../../deps/petal_components/assets/js/petal_components"
  const liveSocket = new LiveSocket("/live", Socket, { hooks: { ...PetalComponents } })
  ```

- For rendered markdown replies, the optional `{:mdex, "~> 0.12"}` dependency.

## The shape

The component family is composition-first:

- `conversation/1` — the scrollable thread + a `:footer` slot for the composer
- `chat_message/1` — a user/assistant bubble (with an optional `:avatar` slot)
- `streaming_text/1` — the in-progress assistant bubble; the `PetalChatStream`
  hook appends tokens you `push_event` to it
- `prompt_input/1` — the composer (Enter to send, Shift+Enter for a newline)

The key idea: **the streaming bubble owns its own DOM** (`phx-update="ignore"`),
so you push token deltas straight to it and LiveView never clobbers them.

## The LiveView

```elixir
defmodule MyAppWeb.ChatLive do
  use MyAppWeb, :live_view

  @stream_id "answer"

  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       messages: [%{role: "assistant", text: "Hi! How can I help?"}],
       draft: "",
       streaming?: false,
       buffer: "",
       task: nil
     )}
  end

  # Keep the textarea value in sync so we can clear it on send.
  def handle_event("draft", %{"prompt" => prompt}, socket) do
    {:noreply, assign(socket, draft: prompt)}
  end

  def handle_event("send", %{"prompt" => prompt}, socket) do
    prompt = String.trim(prompt)

    if prompt == "" or socket.assigns.streaming? do
      {:noreply, socket}
    else
      lv = self()
      # Stream in a task; forward each delta back to this LiveView.
      {:ok, pid} = Task.start(fn -> MyApp.LLM.stream(prompt, lv) end)

      {:noreply,
       socket
       |> update(:messages, &(&1 ++ [%{role: "user", text: prompt}]))
       |> assign(draft: "", streaming?: true, buffer: "", task: pid)}
    end
  end

  # Cancel: kill the task and keep whatever streamed so far.
  def handle_event("stop", _params, socket) do
    if pid = socket.assigns.task, do: Process.exit(pid, :kill)
    {:noreply, commit(socket, socket.assigns.buffer)}
  end

  # Your LLM client sends these messages to the LiveView pid.
  def handle_info({:llm_delta, text}, %{assigns: %{streaming?: true}} = socket) do
    {:noreply,
     socket
     |> push_event("pc-chat-token", %{id: @stream_id, text: text})
     |> update(:buffer, &(&1 <> text))}
  end

  # Ignore stray deltas that arrive after a stop/commit.
  def handle_info({:llm_delta, _text}, socket), do: {:noreply, socket}

  def handle_info(:llm_done, socket), do: {:noreply, commit(socket, socket.assigns.buffer)}

  defp commit(socket, text) do
    socket =
      if String.trim(text) == "",
        do: socket,
        else: update(socket, :messages, &(&1 ++ [%{role: "assistant", text: text}]))

    assign(socket, streaming?: false, buffer: "", task: nil)
  end

  def render(assigns) do
    ~H"""
    <.conversation id="chat">
      <.chat_message :for={msg <- @messages} role={msg.role}>
        <span class="pc-chat__text">{msg.text}</span>
      </.chat_message>

      <.chat_message :if={@streaming?} role="assistant">
        <.streaming_text id={@stream_id} />
      </.chat_message>

      <:footer>
        <.prompt_input
          phx-submit="send"
          phx-change="draft"
          value={@draft}
          loading={@streaming?}
          on_stop="stop"
        />
      </:footer>
    </.conversation>
    """
  end
end
```

That's a complete streaming chat. The contract with your LLM client is two
messages to the LiveView pid: `{:llm_delta, text}` per token and `:llm_done`
when finished.

## Rendering markdown

Assistant replies are usually markdown. Render the **committed** message with
`markdown/1` (sanitized + syntax-highlighted via MDEx):

```heex
<.chat_message :for={msg <- @messages} role={msg.role}>
  <.markdown :if={msg.role == "assistant"} content={msg.text} />
  <span :if={msg.role != "assistant"} class="pc-chat__text">{msg.text}</span>
</.chat_message>
```

### Streaming markdown live

To render markdown *as it streams* (headings/code appear while typing), use a
`format="markdown"` streaming bubble and push throttled HTML instead of raw
text. `PetalComponents.Chat.to_html/1` uses the same engine as `markdown/1`:

```elixir
# in render
<.streaming_text id={@stream_id} format="markdown" />

# accumulate tokens, then render the buffer on a throttle (~100ms)
def handle_info({:llm_delta, text}, %{assigns: %{streaming?: true}} = socket) do
  socket = update(socket, :buffer, &(&1 <> text))

  socket =
    if socket.assigns.flush_scheduled do
      socket
    else
      Process.send_after(self(), :flush_md, 100)
      assign(socket, flush_scheduled: true)
    end

  {:noreply, socket}
end

def handle_info(:flush_md, %{assigns: %{streaming?: true}} = socket) do
  html = PetalComponents.Chat.to_html(socket.assigns.buffer)

  {:noreply,
   socket
   |> push_event("pc-chat-token", %{id: @stream_id, html: html})
   |> assign(flush_scheduled: false)}
end

def handle_info(:flush_md, socket), do: {:noreply, assign(socket, flush_scheduled: false)}
```

> #### Steer the model on fenced markdown {: .tip}
>
> When you ask a model to "show markdown", it tends to nest same-length code
> fences (` ```markdown ` wrapping ` ```elixir `), which is invalid CommonMark
> and renders broken in every renderer. A system prompt fixes it: "when showing
> example markdown that contains code fences, wrap the outer block in more
> backticks than the inner fence."

## Tool calls → widgets (generative UI)

When your model supports function calling, render the result as a real Phoenix
component inside a `tool_call/1` card — the model emits *data*, you map it to UI:

```heex
<.tool_call name="get_weather" status={:complete}>
  <.weather_card city={@city} temp={@temp} />
</.tool_call>
```

Because the widget is a LiveView component, it can have its own `phx-click`,
forms, and streams — not just static markup.

## Other pieces

- `reasoning/1` — a collapsible "thinking" block for reasoning-model output.
- `suggestions/1` — prompt-starter chips for the empty state.
- `message_actions/1` + `copy_button/1` — a copy/regenerate row under a reply.
- `chat_error/1` — an error notice with a retry button.

## Styling

Every component takes a `class` (appended last, so your utilities win), exposes
`--pc-chat-*` CSS variables for theming, and accepts slots for full markup
replacement. See `PetalComponents.Chat` for the per-component reference.
