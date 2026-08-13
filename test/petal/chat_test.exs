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

  describe "citations in markdown/1" do
    setup do
      %{
        sources: [
          %{
            id: "1",
            url: "https://hexdocs.pm/phoenix_live_view",
            title: "Phoenix.LiveView",
            snippet: "Rich, real-time user experiences.",
            favicon_url: "https://hexdocs.pm/favicon.ico"
          },
          %{id: "2", url: "https://hexdocs.pm/phoenix", title: "Phoenix"}
        ]
      }
    end

    test "turns a [^N] marker into a citation chip wired to the matching source", %{
      sources: sources
    } do
      assigns = %{md: "LiveView is great [^1] and so is Phoenix [^2].", sources: sources}

      html = rendered_to_string(~H|<.markdown content={@md} sources={@sources} />|)

      assert_has_class(html, "pc-chat__citation")
      assert html =~ ~s{href="https://hexdocs.pm/phoenix_live_view"}
      assert html =~ ~s{href="https://hexdocs.pm/phoenix"}
      assert html =~ ~s{<sup class="pc-chat__citation-num">1</sup>}
      assert html =~ ~s{<sup class="pc-chat__citation-num">2</sup>}
      # the raw marker is gone
      refute html =~ "[^1]"
    end

    test "without sources the marker passes through as plain text (today's behaviour)" do
      assigns = %{md: "LiveView is great [^1]."}

      html = rendered_to_string(~H|<.markdown content={@md} />|)

      refute html =~ "pc-chat__citation"
      assert html =~ "[^1]"
    end

    test "an unmatched marker renders as plain text, not a broken chip", %{sources: sources} do
      assigns = %{md: "Something unsourced [^9].", sources: sources}

      html = rendered_to_string(~H|<.markdown content={@md} sources={@sources} />|)

      assert html =~ "[^9]"
      refute html =~ "pc-chat__citation-num\">9<"
    end

    test "chips carry an accessible name naming the source", %{sources: sources} do
      assigns = %{md: "Grounded [^1].", sources: sources}

      html = rendered_to_string(~H|<.markdown content={@md} sources={@sources} />|)

      assert html =~ ~s{aria-label="Source 1: Phoenix.LiveView"}
    end

    test "chip links open in a new tab safely", %{sources: sources} do
      assigns = %{md: "Grounded [^1].", sources: sources}

      html = rendered_to_string(~H|<.markdown content={@md} sources={@sources} />|)

      assert html =~ ~s{target="_blank"}
      assert html =~ ~s{rel="noopener noreferrer"}
    end

    test "model-controlled source fields are escaped in the chip and its card" do
      assigns = %{
        md: "Careful [^1].",
        sources: [
          %{
            id: "1",
            url: "https://example.com",
            title: "<script>alert('x')</script>",
            snippet: "<img src=x onerror=alert(1)>"
          }
        ]
      }

      html = rendered_to_string(~H|<.markdown content={@md} sources={@sources} />|)

      refute html =~ "<script>alert"
      refute html =~ "<img src=x"
      assert html =~ "&lt;script&gt;"
      assert html =~ "&lt;img src=x"
    end

    test "markers inside code blocks are left alone", %{sources: sources} do
      assigns = %{md: "```elixir\nfoo = \"[^1]\"\n```", sources: sources}

      html = rendered_to_string(~H|<.markdown content={@md} sources={@sources} />|)

      refute html =~ "pc-chat__citation"
      assert html =~ "[^1]"
    end

    test "a marker resolves positionally when sources have no ids" do
      assigns = %{
        md: "Positional [^2].",
        sources: [%{url: "https://a.example"}, %{url: "https://b.example", title: "B"}]
      }

      html = rendered_to_string(~H|<.markdown content={@md} sources={@sources} />|)

      assert html =~ ~s{href="https://b.example"}
      assert html =~ ~s{aria-label="Source 2: B"}
    end
  end

  describe "to_html/2 with sources (the streaming path)" do
    setup do
      %{sources: [%{id: "1", url: "https://example.com/doc", title: "The Doc"}]}
    end

    test "renders chip markup for complete markers", %{sources: sources} do
      html = PetalComponents.Chat.to_html("Grounded [^1].", sources: sources)

      assert html =~ "pc-chat__citation"
      assert html =~ ~s{href="https://example.com/doc"}
    end

    test "leaves a half-streamed marker untouched so nothing flashes broken", %{sources: sources} do
      html = PetalComponents.Chat.to_html("Grounded [^", sources: sources)

      refute html =~ "pc-chat__citation"
      assert html =~ "[^"
    end

    test "to_html/1 is unchanged" do
      assert PetalComponents.Chat.to_html("Grounded [^1].") =~ "[^1]"
    end
  end

  describe "citation/1" do
    test "renders a standalone chip for a source map" do
      assigns = %{source: %{url: "https://example.com", title: "Example"}}

      html = rendered_to_string(~H|<.citation index={3} source={@source} />|)

      assert_has_class(html, "pc-chat__citation")
      assert html =~ ~s{aria-label="Source 3: Example"}
      assert html =~ ~s{<sup class="pc-chat__citation-num">3</sup>}
    end

    test "the preview card is decorative — the title lives in the accessible name" do
      assigns = %{source: %{url: "https://example.com", title: "Example", snippet: "Snip"}}

      html = rendered_to_string(~H|<.citation index={1} source={@source} />|)

      assert_has_class(html, "pc-chat__citation-card")
      assert html =~ ~s{class="pc-chat__citation-card" aria-hidden="true"}
      assert html =~ "Snip"
    end

    test "class is appended last" do
      assigns = %{source: %{url: "https://example.com"}}

      html = rendered_to_string(~H|<.citation index={1} source={@source} class="custom-chip" />|)

      assert html =~ "custom-chip"
    end
  end

  describe "chat_sources/1" do
    setup do
      %{
        sources: [
          %{
            id: "1",
            url: "https://hexdocs.pm/phoenix_live_view",
            title: "Phoenix.LiveView",
            snippet: "Rich, real-time user experiences.",
            favicon_url: "https://hexdocs.pm/favicon.ico"
          },
          %{id: "2", url: "https://hexdocs.pm/phoenix", title: "Phoenix"},
          %{id: "3", url: "https://elixir-lang.org", title: "Elixir"}
        ]
      }
    end

    test "renders a collapsed details row labelled with the count", %{sources: sources} do
      assigns = %{sources: sources}

      html = rendered_to_string(~H|<.chat_sources sources={@sources} />|)

      assert_has_class(html, "pc-chat__sources")
      assert_has_class(html, "pc-chat__sources-row")
      assert html =~ "<details"
      assert html =~ "<summary"
      assert html =~ "3 sources"
      refute Regex.match?(~r/<details[^>]*\sopen[\s>]/, html)
    end

    test "one source reads in the singular" do
      assigns = %{sources: [%{url: "https://example.com", title: "Only"}]}

      html = rendered_to_string(~H|<.chat_sources sources={@sources} />|)

      assert html =~ "1 source"
      refute html =~ "1 sources"
    end

    test "a custom label overrides the count", %{sources: sources} do
      assigns = %{sources: sources}

      html = rendered_to_string(~H|<.chat_sources sources={@sources} label="Used 3 pages" />|)

      assert html =~ "Used 3 pages"
      refute html =~ "3 sources"
    end

    test "expanded opens the list by default", %{sources: sources} do
      assigns = %{sources: sources}

      html = rendered_to_string(~H|<.chat_sources sources={@sources} expanded />|)

      assert Regex.match?(~r/<details[^>]*\sopen[\s>]/, html)
    end

    test "each source is a safe external link with title, domain and snippet", %{
      sources: sources
    } do
      assigns = %{sources: sources}

      html = rendered_to_string(~H|<.chat_sources sources={@sources} expanded />|)

      assert html =~ ~s{href="https://hexdocs.pm/phoenix_live_view"}
      assert html =~ ~s{target="_blank"}
      assert html =~ ~s{rel="noopener noreferrer"}
      assert html =~ "Phoenix.LiveView"
      assert html =~ "hexdocs.pm"
      assert html =~ "Rich, real-time user experiences."
      assert html =~ ~s{role="list"}
    end

    test "dedupes by url — the same page cited twice is one row" do
      assigns = %{
        sources: [
          %{id: "1", url: "https://example.com/a", title: "A"},
          %{id: "2", url: "https://example.com/a", title: "A again"}
        ]
      }

      html = rendered_to_string(~H|<.chat_sources sources={@sources} expanded />|)

      assert html =~ "1 source"
      refute html =~ "A again"
    end

    test "nil and empty sources render nothing at all" do
      assigns = %{}

      refute rendered_to_string(~H|<.chat_sources sources={[]} />|) =~ "pc-chat__sources"
      refute rendered_to_string(~H|<.chat_sources sources={nil} />|) =~ "pc-chat__sources"
    end

    test "max_visible overflows into a 'Show all' reveal", %{sources: sources} do
      assigns = %{sources: sources}

      html = rendered_to_string(~H|<.chat_sources sources={@sources} expanded max_visible={2} />|)

      assert_has_class(html, "pc-chat__sources-more")
      assert html =~ "Show all (3)"

      html = rendered_to_string(~H|<.chat_sources sources={@sources} expanded max_visible={5} />|)

      refute html =~ "pc-chat__sources-more"
    end

    test "a source without favicon_url degrades to a letter avatar" do
      assigns = %{sources: [%{url: "https://example.com", title: "Example"}]}

      html = rendered_to_string(~H|<.chat_sources sources={@sources} expanded />|)

      assert_has_class(html, "pc-chat__source-favicon--letter")
      assert html =~ ">E<" or html =~ "E\n"
    end

    test "favicons are decorative", %{sources: sources} do
      assigns = %{sources: sources}

      html = rendered_to_string(~H|<.chat_sources sources={@sources} expanded />|)

      assert html =~ ~s{alt=""}
      assert html =~ ~s{loading="lazy"}
    end

    test "a source without a snippet renders a clean row" do
      assigns = %{sources: [%{url: "https://example.com", title: "Example"}]}

      html = rendered_to_string(~H|<.chat_sources sources={@sources} expanded />|)

      refute html =~ "pc-chat__source-snippet"
      assert html =~ "Example"
    end

    test "string-keyed source maps render identically to atom-keyed ones" do
      assigns = %{
        sources: [%{"id" => "1", "url" => "https://example.com", "title" => "Stringy"}]
      }

      html = rendered_to_string(~H|<.chat_sources sources={@sources} expanded />|)

      assert html =~ "Stringy"
      assert html =~ ~s{href="https://example.com"}
    end

    test "class is appended last and rest passes through", %{sources: sources} do
      assigns = %{sources: sources}

      html =
        rendered_to_string(~H|<.chat_sources sources={@sources} class="mine" id="src-block" />|)

      assert html =~ "mine"
      assert html =~ ~s{id="src-block"}
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

  describe "prompt_input/1 attachments" do
    # A minimal UploadConfig standing in for allow_upload/3's, so the composer
    # can be rendered without a live socket.
    defp upload_config(entries, opts \\ []) do
      %Phoenix.LiveView.UploadConfig{
        name: :attachments,
        ref: Keyword.get(opts, :ref, "phx-upload-ref"),
        entries: entries,
        errors: Keyword.get(opts, :errors, []),
        max_entries: 4,
        max_file_size: 5_000_000,
        accept: ".png,.pdf",
        acceptable_types: MapSet.new(["image/png", "application/pdf"]),
        acceptable_exts: MapSet.new([".png", ".pdf"])
      }
    end

    defp upload_entry(opts \\ []) do
      %Phoenix.LiveView.UploadEntry{
        ref: Keyword.get(opts, :ref, "0"),
        upload_ref: "phx-upload-ref",
        client_name: Keyword.get(opts, :client_name, "shot.png"),
        client_size: Keyword.get(opts, :client_size, 12_345),
        client_type: Keyword.get(opts, :client_type, "image/png"),
        progress: Keyword.get(opts, :progress, 0),
        valid?: Keyword.get(opts, :valid?, true),
        done?: false
      }
    end

    test "without an upload the composer is unchanged: no paperclip, drop target or chips" do
      assigns = %{}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" />|)

      refute html =~ "pc-chat__composer-attach"
      refute html =~ "pc-chat__composer-attachments"
      refute html =~ "phx-drop-target"
      refute html =~ ~s{type="file"}
      refute html =~ "pc-chat__composer-errors"
      # the shape that was always there is still there
      assert html =~ "pc-chat__composer-row"
      assert html =~ ~s{name="prompt"}
    end

    test "with an upload it renders the paperclip trigger and a hidden file input" do
      assigns = %{upload: upload_config([])}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      assert_has_class(html, "pc-chat__composer-attach")
      assert html =~ "hero-paper-clip"
      assert html =~ ~s{type="file"}
      assert html =~ "sr-only"
      assert html =~ ~s{aria-label="Attach files"}
      # no entries yet, so no chip strip
      refute html =~ "pc-chat__composer-attachments"
    end

    test "the form becomes a drop target for the upload ref" do
      assigns = %{upload: upload_config([], ref: "upload-123")}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      assert html =~ ~s{phx-drop-target="upload-123"}
    end

    test "an image entry renders a thumbnail chip" do
      assigns = %{upload: upload_config([upload_entry(client_type: "image/png")])}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      assert_has_class(html, "pc-chat__attachment--image")
      assert_has_class(html, "pc-chat__attachment-thumb")
      assert html =~ ~s{role="list"}
    end

    test "a non-image entry renders name and formatted size" do
      assigns = %{
        upload:
          upload_config([
            upload_entry(
              client_type: "application/pdf",
              client_name: "invoice.pdf",
              client_size: 2_400_000
            )
          ])
      }

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      assert_has_class(html, "pc-chat__attachment--file")
      assert html =~ "invoice.pdf"
      assert html =~ "2.4 MB"
      refute html =~ "pc-chat__attachment-thumb"
    end

    test "the progress ring exposes the entry progress and progressbar semantics" do
      assigns = %{upload: upload_config([upload_entry(progress: 42)])}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      assert html =~ ~s{role="progressbar"}
      assert html =~ ~s{aria-valuenow="42"}
      assert html =~ ~s{aria-valuemin="0"}
      assert html =~ ~s{aria-valuemax="100"}
      assert html =~ ~s{aria-label="Uploading shot.png"}
      assert html =~ ~s{data-progress="42"}
      assert html =~ "--pc-attachment-progress: 42"
    end

    test "the progress ring disappears at 100" do
      assigns = %{upload: upload_config([upload_entry(progress: 100)])}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      refute html =~ ~s{role="progressbar"}
    end

    test "nothing is drawn at 0 — the resting state before an upload starts" do
      assigns = %{upload: upload_config([upload_entry(progress: 0)])}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      assert html =~ "pc-chat__attachment"
      refute html =~ ~s{role="progressbar"}
      refute html =~ "pc-chat__attachment-progress"
    end

    test "the remove button pushes the cancel event with the entry ref" do
      assigns = %{upload: upload_config([upload_entry(ref: "entry-7")])}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      assert html =~ ~s{phx-click="cancel-upload"}
      assert html =~ ~s{phx-value-ref="entry-7"}
      assert html =~ ~s{aria-label="Remove shot.png"}
    end

    test "a custom on_cancel_upload name is respected" do
      assigns = %{upload: upload_config([upload_entry()])}

      html =
        rendered_to_string(
          ~H|<.prompt_input phx-submit="send" upload={@upload} on_cancel_upload="drop-it" />|
        )

      assert html =~ ~s{phx-click="drop-it"}
      refute html =~ ~s{phx-click="cancel-upload"}
    end

    test "config-level errors render under the composer as alerts" do
      # upload_errors/1 matches config-level errors by the config's own ref
      assigns = %{upload: upload_config([], errors: [{"phx-upload-ref", :too_many_files}])}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      assert_has_class(html, "pc-chat__composer-errors")
      assert html =~ ~s{role="alert"}
      assert html =~ "Too many files selected."
    end

    test "per-entry errors name the file they belong to" do
      entry = upload_entry(ref: "e1", client_name: "huge.png")

      assigns = %{upload: upload_config([entry], errors: [{"e1", :too_large}])}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      assert html =~ "huge.png: This file is too large."
      assert html =~ ~s{role="alert"}
    end

    test "the not_accepted error gets its own copy" do
      entry = upload_entry(ref: "e1", client_name: "clip.mov")

      assigns = %{upload: upload_config([entry], errors: [{"e1", :not_accepted}])}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      assert html =~ "clip.mov: This file type isn&#39;t accepted."
    end

    test "an upload client failure and an unknown error atom both get readable copy" do
      entry = upload_entry(ref: "e1", client_name: "clip.mov")

      assigns = %{
        upload: upload_config([entry], errors: [{"e1", :external_client_failure}])
      }

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      assert html =~ "clip.mov: Something went wrong uploading this file."

      assigns = %{upload: upload_config([entry], errors: [{"e1", :something_new}])}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      assert html =~ "clip.mov: Upload failed (:something_new)."
    end

    test "accept_hint lands in the accessible description and the tooltip" do
      assigns = %{upload: upload_config([])}

      html =
        rendered_to_string(
          ~H|<.prompt_input phx-submit="send" upload={@upload} accept_hint="PNGs up to 5 MB" />|
        )

      assert html =~ ~s{aria-description="PNGs up to 5 MB"}
      assert html =~ ~s{title="PNGs up to 5 MB"}
    end

    test "no accept_hint means no empty title or aria-description" do
      assigns = %{upload: upload_config([])}

      html = rendered_to_string(~H|<.prompt_input phx-submit="send" upload={@upload} />|)

      refute html =~ "title="
      refute html =~ "aria-description="
    end

    test "chips coexist with the editing banner and the loading stop button" do
      assigns = %{upload: upload_config([upload_entry()])}

      html =
        rendered_to_string(~H"""
        <.prompt_input
          phx-submit="send"
          upload={@upload}
          editing
          on_cancel_edit="cancel"
          loading={true}
          on_stop="stop"
        />
        """)

      assert html =~ "pc-chat__composer-banner"
      assert html =~ "pc-chat__composer-stop"
      assert html =~ "pc-chat__composer-attachments"
    end
  end

  describe "message_attachments/1" do
    test "a single image renders as a lazy thumbnail with the file name as alt text" do
      assigns = %{
        attachments: [%{kind: :image, url: "/uploads/shot.png", name: "shot.png", size: 1200}]
      }

      html = rendered_to_string(~H|<.message_attachments attachments={@attachments} />|)

      assert_has_class(html, "pc-chat__message-attachments")
      assert_has_class(html, "pc-chat__message-attachments-grid")
      assert html =~ ~s{alt="shot.png"}
      assert html =~ ~s{loading="lazy"}
      assert html =~ ~s{src="/uploads/shot.png"}
      refute html =~ "pc-chat__message-attachments-grid--multi"
    end

    test "two or more images tile into a grid" do
      assigns = %{
        attachments: [
          %{kind: :image, url: "/a.png", name: "a.png", size: nil},
          %{kind: :image, url: "/b.png", name: "b.png", size: nil}
        ]
      }

      html = rendered_to_string(~H|<.message_attachments attachments={@attachments} />|)

      assert_has_class(html, "pc-chat__message-attachments-grid--multi")
    end

    test "images are openable in a new tab" do
      assigns = %{attachments: [%{kind: :image, url: "/a.png", name: "a.png", size: nil}]}

      html = rendered_to_string(~H|<.message_attachments attachments={@attachments} />|)

      assert html =~ ~s{target="_blank"}
      assert html =~ ~s{rel="noopener noreferrer"}
    end

    test "files render as download rows with formatted sizes" do
      assigns = %{
        attachments: [
          %{kind: :file, url: "/uploads/invoice.pdf", name: "invoice.pdf", size: 340_000}
        ]
      }

      html = rendered_to_string(~H|<.message_attachments attachments={@attachments} />|)

      assert_has_class(html, "pc-chat__attachment-row")
      assert html =~ "download"
      assert html =~ ~s{href="/uploads/invoice.pdf"}
      assert html =~ "invoice.pdf"
      assert html =~ "340 KB"
    end

    test "a nil size omits the size span" do
      assigns = %{attachments: [%{kind: :file, url: "/a.pdf", name: "a.pdf", size: nil}]}

      html = rendered_to_string(~H|<.message_attachments attachments={@attachments} />|)

      refute html =~ "pc-chat__attachment-size"
      assert html =~ "a.pdf"
    end

    test "a mixed list renders the images before the files" do
      assigns = %{
        attachments: [
          %{kind: :file, url: "/doc.pdf", name: "doc.pdf", size: nil},
          %{kind: :image, url: "/pic.png", name: "pic.png", size: nil}
        ]
      }

      html = rendered_to_string(~H|<.message_attachments attachments={@attachments} />|)

      image_at = :binary.match(html, "pic.png") |> elem(0)
      file_at = :binary.match(html, "doc.pdf") |> elem(0)
      assert image_at < file_at
    end

    test "string-keyed attachment maps render identically" do
      assigns = %{
        attachments: [%{"kind" => "image", "url" => "/x.png", "name" => "x.png", "size" => 100}]
      }

      html = rendered_to_string(~H|<.message_attachments attachments={@attachments} />|)

      assert html =~ ~s{alt="x.png"}
    end

    test "an empty list renders nothing" do
      assigns = %{}

      refute rendered_to_string(~H|<.message_attachments attachments={[]} />|) =~
               "pc-chat__message-attachments"
    end

    test "class is appended last and rest passes through" do
      assigns = %{attachments: [%{kind: :file, url: "/a.pdf", name: "a.pdf", size: nil}]}

      html =
        rendered_to_string(
          ~H|<.message_attachments attachments={@attachments} class="mine" id="att" />|
        )

      assert html =~ "mine"
      assert html =~ ~s{id="att"}
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

  test "prompt_input textarea is uncontrolled (phx-update ignore) so keystrokes never lose focus" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.prompt_input id="cmp" phx-submit="send" value="hello" />
      """)

    assert html =~ ~s(phx-update="ignore")
    assert html =~ ~s(id="cmp-input")
    # the initial value is still rendered as the textarea content
    assert html =~ "hello"
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
