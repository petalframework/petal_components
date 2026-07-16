defmodule PetalComponents.Showcase.Chat do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Chat,
    title: "Chat",
    functions: [
      :conversation,
      :chat_message,
      :streaming_text,
      :prompt_input,
      :tool_call,
      :markdown,
      :rich_text,
      :reasoning,
      :marker,
      :message_actions,
      :copy_button,
      :suggestions,
      :chat_error
    ]

  # Chat is not pulled in by `use PetalComponents`, so import it here.
  import PetalComponents.Chat

  example :flagship, "A complete chat",
    description:
      "The pieces below, assembled - a thread, a tool call, a markdown answer with a highlighted code block, an action bar, starter chips and the composer." do
    ~H"""
    <.conversation id="showcase-chat-flagship" class="w-full max-w-xl mx-auto">
      <.marker variant="separator">Today</.marker>
      <.chat_message role="user">How do I install petal_components?</.chat_message>
      <.tool_call name="search_docs" status={:complete} label="Searched the docs">
        <div class="flex items-center gap-3 text-sm">
          <.icon name="hero-book-open" class="w-8 h-8 text-primary-500" />
          <div>
            <div class="font-medium text-gray-900 dark:text-gray-100">Installation guide</div>
            <div class="text-xs text-gray-500 dark:text-gray-400">hexdocs.pm/petal_components</div>
          </div>
        </div>
      </.tool_call>
      <.chat_message role="assistant">
        <.markdown
          id="showcase-chat-flagship-md"
          content={"Add the dep and pull it in:\n\n```elixir\ndef deps do\n  [{:petal_components, \"~> 4.5\"}]\nend\n```\n\nThen `use PetalComponents` in your web module and every component is a plain HEEx tag."}
        />
        <:actions>
          <.message_actions visible="always">
            <.copy_button
              id="showcase-chat-flagship-copy"
              text={"{:petal_components, \"~> 4.5\"}"}
              icon
            />
            <.action_button icon="hero-hand-thumb-up" label="Good response" phx-click="noop" />
            <.action_button icon="hero-hand-thumb-down" label="Bad response" phx-click="noop" />
            <.action_button icon="hero-arrow-path" label="Regenerate" phx-click="noop" />
          </.message_actions>
        </:actions>
      </.chat_message>
      <:footer>
        <.suggestions
          class="mb-2"
          items={["What makes this different from React AI kits?", "Show me a tool call"]}
          on_select="noop"
        />
        <.prompt_input
          id="showcase-chat-flagship-composer"
          placeholder="Ask about petal_components..."
        />
      </:footer>
    </.conversation>
    """
  end

  example :conversation, "Conversation",
    description:
      "The default plain variant - full-width turns, the ChatGPT / Claude look. Messages are just slots." do
    ~H"""
    <.conversation id="showcase-chat-plain" class="w-full max-w-xl mx-auto">
      <.chat_message role="user">What's the weather in Tokyo?</.chat_message>
      <.chat_message role="assistant">
        It's 22°C and clear in Tokyo right now, with a light breeze from the south.
      </.chat_message>
    </.conversation>
    """
  end

  example :bubbles, "Bubbles",
    description: "Pass variant=\"bubbles\" for the messaging-app layout." do
    ~H"""
    <.conversation id="showcase-chat-bubbles" variant="bubbles" class="w-full max-w-xl mx-auto">
      <.chat_message role="user">Can you summarise this in one line?</.chat_message>
      <.chat_message role="assistant">
        It's a Phoenix component library that ships an MCP server so AI tools use the real API.
      </.chat_message>
    </.conversation>
    """
  end

  example :tool_call, "Tool calls",
    description:
      "Generative UI. The model emits data, you map the tool name to a real Phoenix component. status drives the header: running spins, complete checks, error warns." do
    ~H"""
    <div class="w-full max-w-xl mx-auto space-y-3">
      <.tool_call name="search_web" status={:running} label="Searching the web" />
      <.tool_call name="get_weather" status={:complete}>
        <div class="flex items-center justify-between px-4 py-3 text-white rounded-lg bg-gradient-to-br from-sky-500 to-indigo-600">
          <div>
            <div class="text-sm font-medium opacity-90">Tokyo</div>
            <div class="text-2xl font-bold">21°C</div>
          </div>
          <div class="text-4xl">☀️</div>
        </div>
      </.tool_call>
      <.tool_call name="charge_card" status={:error} label="Payment failed" />
    </div>
    """
  end

  example :reasoning, "Reasoning",
    description: "A collapsible thinking block for reasoning-model output." do
    ~H"""
    <div class="w-full max-w-xl mx-auto">
      <.reasoning label="Thought for 2s" open>
        First I considered the user's location, then looked up the current conditions and picked the most relevant detail.
      </.reasoning>
    </div>
    """
  end

  example :markdown, "Markdown",
    description:
      "Render a committed assistant reply as sanitized, syntax-highlighted markdown. Needs the optional :mdex dep." do
    ~H"""
    <div class="w-full max-w-xl mx-auto">
      <.markdown content={"## Forecast\n\nTokyo is **21°C** and sunny.\n\n- Light breeze\n- UV index moderate\n\n```elixir\nIO.puts(\"pack light\")\n```"} />
    </div>
    """
  end

  example :message_actions, "Message actions",
    description:
      "A row of actions under a reply. copy_button copies text client-side via a bundled hook." do
    ~H"""
    <.message_actions class="max-w-xl mx-auto">
      <.copy_button id="showcase-chat-copy" text="The full assistant reply, copied to the clipboard." />
      <button type="button" class="pc-chat__action" phx-click="noop">Regenerate</button>
    </.message_actions>
    """
  end

  example :suggestions, "Suggestions",
    description:
      "Prompt-starter chips for the empty state. Each pushes on_select with phx-value-prompt." do
    ~H"""
    <.suggestions
      class="max-w-xl mx-auto"
      items={["What is Phoenix LiveView?", "Show me a markdown demo", "Write a haiku"]}
      on_select="suggestion"
    />
    """
  end

  example :chat_error, "Error", description: "An error notice with an optional retry button." do
    ~H"""
    <div class="w-full max-w-xl mx-auto">
      <.chat_error on_retry="retry">
        Something went wrong generating a response.
      </.chat_error>
    </div>
    """
  end

  example :markers, "Markers",
    description:
      "Section dividers between turns - a date, a \"new messages\" line, or a tool-call header." do
    ~H"""
    <.conversation id="showcase-chat-markers" class="w-full max-w-xl mx-auto">
      <.marker variant="separator">Today</.marker>
      <.chat_message role="user">Pick up where we left off.</.chat_message>
      <.marker variant="border" icon="hero-wrench-screwdriver">Running search_docs</.marker>
      <.chat_message role="assistant">Found 3 matches. Here's the most relevant one.</.chat_message>
    </.conversation>
    """
  end

  example :prompt_input, "Prompt input",
    description:
      "The composer - an autogrowing textarea with the arrow-up send button. Enter submits, Shift+Enter adds a line." do
    ~H"""
    <div class="w-full max-w-xl mx-auto">
      <.prompt_input id="showcase-chat-composer" placeholder="Message the assistant..." />
    </div>
    """
  end
end
