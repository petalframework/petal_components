defmodule PetalComponents.ChatTest do
  use ComponentCase
  import PetalComponents.Chat

  describe "conversation/1" do
    test "renders the thread container, inner content, and footer" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.conversation id="thread">
          <div>hello</div>
          <:footer>footer-here</:footer>
        </.conversation>
        """)

      assert_has_class(html, "pc-chat")
      assert_has_class(html, "pc-chat__thread")
      assert_has_class(html, "pc-chat__footer")
      assert html =~ ~s{id="thread"}
      assert html =~ "hello"
      assert html =~ "footer-here"
    end

    test "generates a unique id when none is given (so multiple threads coexist)" do
      assigns = %{}
      [_, id1] = Regex.run(~r/id="(pc-chat-[^"]+)"/, rendered_to_string(~H|<.conversation>
  <div>x</div>
</.conversation>|))
      [_, id2] = Regex.run(~r/id="(pc-chat-[^"]+)"/, rendered_to_string(~H|<.conversation>
  <div>x</div>
</.conversation>|))

      refute id1 == id2
    end

    test "omits the footer wrapper when no footer slot is given" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.conversation>
          <div>only body</div>
        </.conversation>
        """)

      refute html =~ "pc-chat__footer"
    end
  end

  describe "chat_message/1" do
    test "renders a role-specific bubble" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chat_message role="user">hi there</.chat_message>
        """)

      assert_has_class(html, "pc-chat__row--user")
      assert_has_class(html, "pc-chat__bubble--user")
      assert html =~ "hi there"
    end

    test "appends a user class last so it can override" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chat_message role="assistant" class="custom-skin">x</.chat_message>
        """)

      assert html =~ "custom-skin"
      assert_has_class(html, "pc-chat__bubble--assistant")
    end

    test "renders an avatar slot when provided" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chat_message role="assistant">
          <:avatar>AV</:avatar>
          body
        </.chat_message>
        """)

      assert_has_class(html, "pc-chat__avatar")
      assert html =~ "AV"
    end
  end

  describe "streaming_text/1" do
    test "renders a hook-driven, self-owned element with typing indicator and caret" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.streaming_text id="answer" />
        """)

      assert html =~ ~s{id="answer"}
      assert html =~ ~s{phx-hook="PetalChatStream"}
      assert html =~ ~s{phx-update="ignore"}
      assert html =~ ~s{data-event="pc-chat-token"}
      assert html =~ "data-pc-stream-text"
      assert_has_class(html, "pc-chat__typing")
      assert_has_class(html, "pc-chat__caret")
    end

    test "accepts a custom push_event name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.streaming_text id="answer" event="my-tokens" />
        """)

      assert html =~ ~s{data-event="my-tokens"}
    end

    test "markdown format renders an html target instead of a text node" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.streaming_text id="answer" format="markdown" />
        """)

      assert html =~ "data-pc-stream-html"
      assert_has_class(html, "pc-chat__markdown")
      refute html =~ "data-pc-stream-text"
    end
  end

  describe "to_html/1" do
    test "renders sanitized markdown html" do
      assert PetalComponents.Chat.to_html("# Hi\n\n**bold**") =~ "<h1>Hi</h1>"
      assert PetalComponents.Chat.to_html("**bold**") =~ "<strong>bold</strong>"
      refute PetalComponents.Chat.to_html("<script>x</script>\n\nok") =~ "<script>"
    end
  end

  describe "tool_call/1" do
    test "renders the tool name and a completed check" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tool_call name="get_weather" status={:complete}>
          <div>widget here</div>
        </.tool_call>
        """)

      assert_has_class(html, "pc-chat__tool")
      assert_has_class(html, "pc-chat__tool--complete")
      assert_has_class(html, "pc-chat__tool-check")
      assert html =~ "get_weather"
      assert html =~ "widget here"
    end

    test "shows a spinner while running and supports a custom label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tool_call name="search" status={:running} label="Searching the web" />
        """)

      assert_has_class(html, "pc-chat__tool-spinner")
      assert html =~ "Searching the web"
      refute html =~ "pc-chat__tool-check"
    end
  end

  describe "markdown/1" do
    test "renders markdown as html (headings, bold, code)" do
      assigns = %{md: "# Title\n\nsome **bold** and `code`"}

      html = rendered_to_string(~H|<.markdown content={@md} />|)

      assert_has_class(html, "pc-chat__markdown")
      assert html =~ "<h1>Title</h1>"
      assert html =~ "<strong>bold</strong>"
      assert html =~ "<code>code</code>"
    end

    test "sanitizes dangerous html" do
      assigns = %{md: "Hello\n\n<script>alert('x')</script>\n\nworld"}

      html = rendered_to_string(~H|<.markdown content={@md} />|)

      refute html =~ "<script>"
      assert html =~ "Hello"
      assert html =~ "world"
    end

    test "handles nil content" do
      assigns = %{}
      html = rendered_to_string(~H|<.markdown content={nil} />|)
      assert_has_class(html, "pc-chat__markdown")
    end
  end

  describe "rich_text/1" do
    test "interleaves markdown prose with a widget directive" do
      assigns = %{
        rw: fn name, args ->
          Phoenix.HTML.raw(~s|<span class="w">#{name}:#{args["city"]}</span>|)
        end,
        md: "Before text\n\n```widget:weather\n{\"city\":\"Paris\"}\n```\n\nAfter text"
      }

      html = rendered_to_string(~H|<.rich_text content={@md} render_widget={@rw} />|)

      assert html =~ "Before text"
      assert html =~ "After text"
      assert html =~ ~s|class="w"|
      assert html =~ "weather:Paris"
      # the directive must NOT render as a literal code block
      refute html =~ "widget:weather"
    end

    test "leaves normal code fences as code blocks" do
      assigns = %{md: "```elixir\nx = 1\n```"}

      html = rendered_to_string(~H|<.rich_text content={@md} />|)

      assert html =~ "<pre"
      assert html =~ "language-elixir"
    end
  end

  describe "reasoning/1" do
    test "renders a collapsible details block" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.reasoning label="Thought for 2s" open>step one</.reasoning>
        """)

      assert_has_class(html, "pc-chat__reasoning")
      assert html =~ "<details"
      assert html =~ "open"
      assert html =~ "Thought for 2s"
      assert html =~ "step one"
    end
  end

  describe "copy_button/1 and message_actions/1" do
    test "copy_button carries the text and copy hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.copy_button id="c1" text="hello world" />
        """)

      assert html =~ ~s{phx-hook="PetalCopy"}
      assert html =~ ~s{data-copy-text="hello world"}
      assert_has_class(html, "pc-chat__action")
    end

    test "message_actions wraps its children" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.message_actions><button>x</button></.message_actions>
        """)

      assert_has_class(html, "pc-chat__actions")
      assert html =~ "<button>x</button>"
    end
  end

  describe "suggestions/1" do
    test "renders a chip per item pushing the select event with the prompt" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.suggestions items={["Alpha", "Beta"]} on_select="pick" />
        """)

      assert_has_class(html, "pc-chat__suggestions")
      assert html =~ ~s{phx-click="pick"}
      assert html =~ ~s{phx-value-prompt="Alpha"}
      assert html =~ "Beta"
    end
  end

  describe "chat_error/1" do
    test "renders an alert with an optional retry button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chat_error on_retry="retry">It broke</.chat_error>
        """)

      assert_has_class(html, "pc-chat__error")
      assert html =~ ~s{role="alert"}
      assert html =~ "It broke"
      assert html =~ ~s{phx-click="retry"}
    end

    test "omits the retry button when on_retry is nil" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chat_error>It broke</.chat_error>
        """)

      refute html =~ "pc-chat__retry"
    end
  end

  describe "prompt_input/1" do
    test "renders a form with a named textarea and send button" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.prompt_input phx-submit="send" value="draft text" submit_label="Go" />
        """)

      assert_has_class(html, "pc-chat__composer")
      assert html =~ ~s{phx-hook="PetalChatComposer"}
      assert html =~ ~s{phx-submit="send"}
      assert html =~ ~s{name="prompt"}
      assert html =~ "draft text"
      assert html =~ "Go"
    end

    test "labels the textarea for screen readers" do
      assigns = %{}
      html = rendered_to_string(~H|<.prompt_input phx-submit="send" />|)
      assert html =~ ~s{aria-label="Message"}
    end

    test "shows a stop button (not a disabled input) while loading with on_stop" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.prompt_input phx-submit="send" loading={true} on_stop="stop" />
        """)

      assert_has_class(html, "pc-chat__composer-stop")
      assert html =~ ~s{phx-click="stop"}
      # input stays editable (no disabled anywhere) so the user can draft ahead
      refute html =~ "disabled"
      refute html =~ "pc-chat__composer-send"
    end

    test "falls back to a disabled send button while loading without on_stop" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.prompt_input phx-submit="send" loading={true} />
        """)

      assert html =~ "disabled"
      refute html =~ "pc-chat__composer-stop"
    end
  end

  describe "marker" do
    test "inline with icon" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.marker icon="hero-magnifying-glass">Searched the web</.marker>
        """)

      assert html =~ "pc-chat__marker"
      assert html =~ "pc-chat__marker--inline"
      assert html =~ "hero-magnifying-glass"
      assert html =~ "Searched the web"
      refute html =~ ~s(role="status")
    end

    test "separator and border variants" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.marker variant="separator">Today</.marker>
        """)

      assert html =~ "pc-chat__marker--separator"

      html =
        rendered_to_string(~H"""
        <.marker variant="border">Context compacted</.marker>
        """)

      assert html =~ "pc-chat__marker--border"
    end

    test "loading shows the spinner and announces as a status region" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.marker loading icon="hero-cpu-chip">Thinking...</.marker>
        """)

      assert html =~ "pc-chat__marker-spinner"
      assert html =~ ~s(role="status")
      # spinner replaces the icon while loading
      refute html =~ "hero-cpu-chip"
    end
  end

  describe "message action bar" do
    test "send button defaults to the arrow icon and takes text via submit_label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.prompt_input phx-submit="send" />
        """)

      assert html =~ "pc-chat__composer-send--icon"
      assert html =~ "hero-arrow-up"
      assert html =~ ~s(aria-label="Send message")

      html =
        rendered_to_string(~H"""
        <.prompt_input phx-submit="send" submit_label="Send" />
        """)

      assert html =~ ">Send" or html =~ "Send\n"
      refute html =~ "pc-chat__composer-send--icon"
    end

    test "action_button renders icon-only with accessible name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.action_button icon="hero-hand-thumb-up" label="Good response" phx-click="fb" />
        """)

      assert html =~ "pc-chat__action--icon"
      assert html =~ "hero-hand-thumb-up"
      assert html =~ ~s(aria-label="Good response")
      assert html =~ ~s(title="Good response")
    end

    test "copy_button icon mode swaps clipboard for check feedback" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.copy_button id="c2" text="abc" icon />
        """)

      assert html =~ "data-pc-copy-default"
      assert html =~ "data-pc-copy-done"
      assert html =~ "hero-clipboard"
      assert html =~ "hero-check"
      assert html =~ ~s(aria-label="Copy")
    end

    test "message_actions hover mode adds the reveal class" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.message_actions visible="hover"><button>x</button></.message_actions>
        """)

      assert html =~ "pc-chat__actions--hover"

      html =
        rendered_to_string(~H"""
        <.message_actions><button>x</button></.message_actions>
        """)

      refute html =~ "pc-chat__actions--hover"
    end
  end

  test "reasoning shows a rotating disclosure chevron" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.reasoning label="Thought for 3s">trace</.reasoning>
      """)

    assert html =~ "pc-chat__reasoning-chevron"
    assert html =~ "hero-chevron-right"
  end

  describe "prompt_input edit banner" do
    test "editing shows the banner with a cancel control" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.prompt_input phx-submit="send" editing on_cancel_edit="cancel" />
        """)

      assert html =~ "pc-chat__composer--editing"
      assert html =~ "pc-chat__composer-banner"
      assert html =~ "Editing message"
      assert html =~ "hero-pencil-square"
      assert html =~ ~s(aria-label="Cancel edit")
      assert html =~ ~s(phx-click="cancel")
    end

    test "no banner when not editing; row wrapper is always present" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.prompt_input phx-submit="send" />
        """)

      refute html =~ "pc-chat__composer-banner"
      refute html =~ "pc-chat__composer--editing"
      assert html =~ "pc-chat__composer-row"
    end

    test "custom edit_label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.prompt_input phx-submit="send" editing edit_label="Editing your question" />
        """)

      assert html =~ "Editing your question"
    end
  end

  describe "conversation variants and the actions slot" do
    test "plain is the default; bubbles opts back in" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.conversation id="v1">hi</.conversation>
        """)

      assert html =~ "pc-chat--plain"

      html =
        rendered_to_string(~H"""
        <.conversation id="v2" variant="bubbles">hi</.conversation>
        """)

      refute html =~ "pc-chat--plain"
    end

    test "the actions slot works on a user message too (copy/edit)" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chat_message role="user">
          How do I install?
          <:actions>
            <.message_actions>
              <.copy_button id="uq" text="How do I install?" icon />
              <.action_button icon="hero-pencil-square" label="Edit" phx-click="edit" />
            </.message_actions>
          </:actions>
        </.chat_message>
        """)

      assert html =~ "pc-chat__row--user"
      assert html =~ "pc-chat__row-actions"
      assert html =~ "hero-pencil-square"
      assert html =~ ~s(aria-label="Edit")
    end

    test "chat_message :actions renders below the bubble, outside it" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.chat_message role="assistant">
          Answer text
          <:actions>
            <.message_actions><button>copy</button></.message_actions>
          </:actions>
        </.chat_message>
        """)

      assert html =~ "pc-chat__body"
      assert html =~ "pc-chat__row-actions"
      # the actions container closes after the bubble does
      bubble_close = :binary.match(html, "pc-chat__row-actions") |> elem(0)
      bubble_open = :binary.match(html, "pc-chat__bubble") |> elem(0)
      assert bubble_open < bubble_close
    end
  end
end
