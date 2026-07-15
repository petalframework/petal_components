defmodule PetalComponents.Showcase.Chat do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Chat,
    title: "Chat",
    functions: [:conversation, :chat_message, :marker, :prompt_input]

  # Chat is not pulled in by `use PetalComponents`, so import it here.
  import PetalComponents.Chat

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
