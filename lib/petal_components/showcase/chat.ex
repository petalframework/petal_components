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
      :chat_error,
      :chat_sources,
      :citation,
      :message_attachments,
      :questionnaire
    ]

  @framework_spec %{
    id: "showcase-q-framework",
    title: "Which framework are you targeting?",
    description: "This picks the generators I'll reach for.",
    fields: [
      %{
        id: "framework",
        type: :single_select,
        label: "Framework",
        required: true,
        options: [
          %{value: "phoenix", label: "Phoenix", description: "Elixir, LiveView, server-rendered"},
          %{value: "rails", label: "Rails", description: "Ruby, Hotwire, convention-first"},
          %{value: "next", label: "Next.js", description: "React, app router, RSC"}
        ]
      }
    ]
  }

  @scoping_spec %{
    id: "showcase-q-scope",
    title: "Before I scaffold, two things",
    fields: [
      %{
        id: "features",
        type: :multi_select,
        label: "Which features do you need?",
        options: [
          %{value: "auth", label: "Auth"},
          %{value: "billing", label: "Billing"},
          %{value: "admin", label: "Admin panel"}
        ]
      },
      %{id: "team", type: :text, label: "Team name", placeholder: "Platform"},
      %{
        id: "confidence",
        type: :scale,
        label: "How settled is this scope?",
        min_label: "Still exploring",
        max_label: "Locked",
        required: true
      }
    ]
  }

  @rag_sources [
    %{
      id: "1",
      url: "https://hexdocs.pm/phoenix_live_view/Phoenix.LiveView.html",
      title: "Phoenix.LiveView — behaviour and lifecycle",
      snippet:
        "LiveView provides rich, real-time user experiences with server-rendered HTML over a persistent connection."
    },
    %{
      id: "2",
      url: "https://hexdocs.pm/phoenix_live_view/js-interop.html",
      title: "JavaScript interoperability",
      snippet: "Client hooks let you run JavaScript when an element is added, updated or removed."
    },
    %{
      id: "3",
      url: "https://hexdocs.pm/phoenix/Phoenix.Endpoint.html",
      title: "Phoenix.Endpoint",
      snippet: "The endpoint is the boundary where all requests to your application start."
    },
    %{
      id: "4",
      url: "https://elixir-lang.org/getting-started/processes.html",
      title: "Processes"
    }
  ]

  # Chat is not pulled in by `use PetalComponents`, so import it here.
  import PetalComponents.Chat

  # Inline SVG placeholders: the examples have to render standalone on
  # petal.build and in the playground, so they can't reach for a static asset.
  @shot_image "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='480' height='300'><rect width='100%' height='100%' fill='%23e2e8f0'/><rect x='24' y='24' width='432' height='40' rx='6' fill='%23cbd5e1'/><rect x='24' y='88' width='300' height='16' rx='4' fill='%23cbd5e1'/><rect x='24' y='120' width='240' height='16' rx='4' fill='%23cbd5e1'/><rect x='24' y='176' width='432' height='96' rx='6' fill='%23fecaca'/><text x='40' y='232' font-family='monospace' font-size='18' fill='%23991b1b'>CardTokenExpired</text></svg>"

  @logs_image "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' width='480' height='300'><rect width='100%' height='100%' fill='%231e293b'/><rect x='20' y='28' width='380' height='12' rx='3' fill='%2394a3b8'/><rect x='20' y='60' width='300' height='12' rx='3' fill='%2394a3b8'/><rect x='20' y='92' width='420' height='12' rx='3' fill='%23f87171'/><rect x='20' y='124' width='260' height='12' rx='3' fill='%2394a3b8'/><rect x='20' y='156' width='340' height='12' rx='3' fill='%2394a3b8'/><rect x='20' y='188' width='200' height='12' rx='3' fill='%2394a3b8'/></svg>"

  # Examples render with `assigns = %{}`, so the seed data comes from here
  # rather than an assign.
  defp rag_sources, do: @rag_sources
  defp shot_image, do: @shot_image
  defp logs_image, do: @logs_image
  defp framework_spec, do: @framework_spec
  defp scoping_spec, do: @scoping_spec

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

  example :chat_sources, "Sources and citations",
    description:
      "Answer grounding for RAG. Prompt the model to cite as [^N]; pass the same source maps to markdown/1 and the markers become chips (hover or tab to one for the preview card). chat_sources renders the deduped list below - native <details>, no JS." do
    ~H"""
    <.conversation id="showcase-chat-sources" class="w-full max-w-xl mx-auto">
      <.chat_message role="user">How does LiveView keep the page in sync?</.chat_message>
      <.chat_message role="assistant">
        <.markdown
          content="LiveView holds a **persistent connection** and diffs the rendered tree server-side, pushing only what changed [^1]. Anything the server can't own - focus, clipboard, third-party widgets - drops down to a client hook [^2].\n\nEvery request still enters through the endpoint [^3]."
          sources={rag_sources()}
        />
        <.chat_sources sources={rag_sources()} />
      </.chat_message>
    </.conversation>
    """
  end

  example :chat_sources_expanded, "Sources expanded",
    description:
      "expanded opens the row on render; max_visible caps the list and tucks the rest behind a \"Show all\" reveal. A source with no favicon_url falls back to a letter avatar, and no snippet just means a shorter row." do
    ~H"""
    <div class="w-full max-w-xl mx-auto">
      <.chat_sources sources={rag_sources()} expanded max_visible={2} />
    </div>
    """
  end

  example :citation, "Citation chip",
    description:
      "The chip on its own, for prose you assemble yourself. It's a real link - Tab reaches it, the preview card opens on hover or focus, and activating it opens the source in a new tab." do
    ~H"""
    <p class="w-full max-w-xl mx-auto text-sm text-gray-700 dark:text-gray-300">
      Processes in Elixir are cheap and isolated
      <.citation index={4} source={Enum.at(rag_sources(), 3)} />
      which is why a LiveView per tab is unremarkable
      <.citation index={1} source={Enum.at(rag_sources(), 0)} />.
    </p>
    """
  end

  example :message_attachments, "Message attachments",
    description:
      "What the user sent along with the text. Images tile into a grid, files are download rows with the size on the end. A mixed list puts the images first." do
    ~H"""
    <.conversation id="showcase-chat-attachments" class="w-full max-w-xl mx-auto">
      <.chat_message role="user">
        <.message_attachments attachments={[
          %{kind: :image, url: shot_image(), name: "checkout-error.png", size: 184_320},
          %{kind: :image, url: logs_image(), name: "server-logs.png", size: 92_100},
          %{kind: :file, url: "#", name: "invoice-4471.pdf", size: 96_400}
        ]} /> The checkout page throws on submit. Screenshot, logs and the invoice attached.
      </.chat_message>
      <.chat_message role="assistant">
        Thanks - the stack trace in that screenshot points at the card token
        expiring before submit. I can see the charge attempt on invoice 4471.
      </.chat_message>
    </.conversation>
    """
  end

  example :questionnaire, "Questionnaire",
    description:
      "The model pauses to ask a structured question and the answer lands in the transcript. Server-driven: a plain phx-submit, no client state. Options with descriptions render as radio cards, plain ones as radios." do
    ~H"""
    <.conversation id="showcase-chat-questionnaire" class="w-full max-w-xl mx-auto">
      <.chat_message role="user">Scaffold me a starter app.</.chat_message>
      <.chat_message role="assistant">
        <.questionnaire spec={framework_spec()} allow_skip />
      </.chat_message>
    </.conversation>
    """
  end

  example :questionnaire_mixed, "Questionnaire - mixed fields",
    description:
      "All four field types in one bubble: multi-select, short text, and a 1-to-5 scale with end captions. Required fields use the native required attribute, so enforcement is the browser's." do
    ~H"""
    <div class="w-full max-w-xl mx-auto">
      <.questionnaire spec={scoping_spec()} submit_label="Send answers" />
    </div>
    """
  end

  example :questionnaire_resolved, "Questionnaire - resolved and skipped",
    description:
      "Once the app has the answer, pass it back as resolved and the form becomes quiet chips - nothing focusable is left behind. :skipped renders the one-line skipped state." do
    ~H"""
    <.conversation id="showcase-chat-questionnaire-resolved" class="w-full max-w-xl mx-auto">
      <.chat_message role="assistant">
        <.questionnaire spec={framework_spec()} resolved={%{"framework" => "phoenix"}} />
      </.chat_message>
      <.chat_message role="assistant">
        <.questionnaire
          spec={scoping_spec()}
          resolved={
            %{
              "features" => ["auth", "billing"],
              "team" => "Platform",
              "confidence" => "5"
            }
          }
        />
      </.chat_message>
      <.chat_message role="assistant">
        <.questionnaire spec={framework_spec()} resolved={:skipped} />
      </.chat_message>
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
