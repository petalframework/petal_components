defmodule PetalComponents do
  @moduledoc """
  Importing `use PetalComponents` brings the core component set into scope as
  unqualified function components (`<.button>`, `<.modal>`, `<.table>`, …).

  The `PetalComponents.Chat` family (`conversation`, `chat_message`, `markdown`,
  `tool_call`, …) is intentionally **not** part of this import. It defines
  generically-named functions like `markdown/1` that would clash with an app's
  own helpers, so you opt into it explicitly and call it namespaced:

      alias PetalComponents.Chat

      <Chat.conversation id="chat">
        <Chat.chat_message role="assistant"><Chat.markdown content={@text} /></Chat.chat_message>
      </Chat.conversation>

  See the [streaming chat guide](streaming_chat.html) for the full setup.
  """
  defmacro __using__(_) do
    quote do
      import PetalComponents.{
        Accordion,
        Alert,
        Avatar,
        Badge,
        Aurora,
        BorderBeam,
        Breadcrumbs,
        Button,
        ButtonGroup,
        Card,
        Chart,
        Confetti,
        Container,
        Dropdown,
        Field,
        Form,
        Icon,
        Input,
        Command,
        InputGroup,
        InputOtp,
        Link,
        Loading,
        Marquee,
        Meteors,
        Modal,
        NavigationMenu,
        NumberTicker,
        Pagination,
        Popover,
        Progress,
        Rating,
        Skeleton,
        SlideOver,
        Sparkline,
        ShineBorder,
        SpotlightCard,
        Stepper,
        Table,
        Tabs,
        Tooltip,
        TextAnimation,
        Typography,
        UserDropdownMenu,
        Menu
      }

      alias PetalComponents.HeroiconsV1
    end
  end

  # Deprecated: components no longer use Alpine.js — they're LiveView.JS only.
  # Kept for backwards-compatibility; always returns "live_view_js".
  @default_js_lib Application.compile_env(:petal_components, :default_js_lib, "live_view_js")
  def default_js_lib() do
    @default_js_lib
  end
end
