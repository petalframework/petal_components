defmodule PetalComponents.Showcase.Frame do
  @moduledoc """
  The shared presentation shell for showcase examples - the piece that makes the
  dev playground and petal.build render example blocks identically.

  `showcase_example/1` joins a live preview to a `code_block/1` - the one code
  surface both sites use for every code panel (examples, hero snippets, Get
  Code, recipes, docs). The block's toggles are pure CSS (hidden inputs +
  `:has()` rules in `default.css`) so it needs no Alpine and no hook and works
  in dead views. Code is highlighted server-side via the optional `:lumis`
  dependency into classed tokens whose colours live in CSS, falling back to
  plain code when lumis is absent.

  `showcase_props/1` renders a component's attrs/slots table straight from
  `Phoenix.Component.__components__/0`, so props documentation can never drift.
  """
  use Phoenix.Component
  import PetalComponents.Icon

  alias PetalComponents.Showcase.Example
  alias PetalComponents.Showcase.Highlight

  # Shown on `inert` previews. These examples render a fixed state that cannot
  # answer a click, so the frame says so rather than letting a live-looking
  # button swallow it silently.
  @static_hint "This preview renders a fixed state, so its controls do not respond. The code below is the real, working markup."

  attr :example, Example, required: true

  attr :id, :string,
    default: nil,
    doc:
      "DOM id for the frame; defaults to one derived from the example id. Set it if the same example renders twice on one page"

  attr :locked, :boolean,
    default: false,
    doc: "blur the code behind a login CTA (the surface decides)"

  attr :show_code, :boolean, default: true

  attr :content_left, :boolean,
    default: false,
    doc: "left-align the preview instead of centering it"

  attr :class, :any, default: nil
  slot :locked_overlay, doc: "shown over the blurred code when locked; defaults to a lock hint"

  @doc "Renders one showcase example: a live preview with its code block attached underneath."
  def showcase_example(assigns) do
    # The id must be deterministic (derived from the example, not a counter):
    # LiveView re-renders regenerate function-component assigns, and a changing
    # id would defeat the phx-update="ignore" state inside the code block,
    # resetting the user's expanded/collapsed state on every patch.
    assigns =
      assigns
      |> assign(:frame_id, assigns.id || "pcsx-#{assigns.example.id}")
      |> assign(:static_hint, @static_hint)

    ~H"""
    <div id={@frame_id} class={["pc-showcase not-prose", @class]}>
      <div
        class={["pc-showcase__preview", !@content_left && "pc-showcase__preview--center"]}
        inert={@example.inert}
      >
        {@example.render.(assigns)}
      </div>

      <%!-- Deliberately a SIBLING of the inert div, not a child: `inert` strips
      its whole subtree from the accessibility tree, so a badge nested inside
      the preview would be invisible to exactly the readers who cannot discover
      "nothing happens when I click" by clicking. --%>
      <span :if={@example.inert} class="pc-showcase__static" title={@static_hint}>
        <.icon name="hero-eye" class="w-3 h-3" aria-hidden="true" />
        <span>Static preview</span>
        <span class="sr-only">- {@static_hint}</span>
      </span>

      <.code_block
        :if={@show_code}
        id={"#{@frame_id}-code"}
        code={@example.code}
        highlighted={@example.highlighted}
        attached
        locked={@locked}
      >
        <:locked_overlay :if={@locked_overlay != []}>{render_slot(@locked_overlay)}</:locked_overlay>
      </.code_block>
    </div>
    """
  end

  # The pure-CSS file tabs carry one :has() rule per index in default.css, so a
  # file past this count could never be shown. Raise instead of hiding it.
  @max_files 12

  attr :id, :string,
    required: true,
    doc: "DOM id; the expand toggle, file tabs and copy buttons derive theirs from it"

  attr :code, :string, default: nil, doc: "a single snippet (ignored when `files` is given)"

  attr :language, :string,
    default: nil,
    doc:
      "the snippet's language, for highlighting; defaults to the filename's extension, else heex"

  attr :filename, :string,
    default: nil,
    doc: "names the snippet; a named snippet gets the file header, like a one-file `files`"

  attr :highlighted, :any,
    default: nil,
    doc: "precompiled `{:safe, html}` for `code` (showcase examples highlight at compile time)"

  attr :files, :list,
    default: nil,
    doc:
      "several files, one tab each: maps with `:name` and `:code`, plus `:language` when the name's extension does not say it"

  attr :collapsible, :any,
    default: :auto,
    values: [:auto, true, false],
    doc: "fold long code behind View code; `:auto` folds anything past five lines"

  attr :attached, :boolean,
    default: false,
    doc: "sit flush under a preview: top border only, square top corners"

  attr :locked, :boolean,
    default: false,
    doc: "blur the code behind an overlay (the surface decides who may see it)"

  attr :wrap, :boolean,
    default: false,
    doc: "wrap long lines instead of scrolling sideways - for prose such as an agent prompt"

  attr :copy, :boolean, default: true, doc: "show the copy button"
  attr :class, :any, default: nil
  slot :locked_overlay, doc: "shown over the blurred code when locked; defaults to a lock hint"

  @doc """
  The one code surface: every code panel on the playground and petal.build
  renders through it, so its look is tuned in one place (`.pc-code` in
  `default.css`).

  One component, a few shapes:

    * a bare `code` snippet - no header, the copy button sits in the corner
    * a named snippet (`filename`) - a quiet header naming the file
    * `files` - the same header holding one tab per file
    * `collapsible` - long code folds behind View code (automatic past five
      lines); copy appears once it is open. Open code is capped at
      `--pc-code-max-height` (24rem) and scrolls, so there is no fold-back
    * `attached` - flush under a preview, as in `showcase_example/1`
    * `locked` - blurred behind an overlay

  The expand toggle and file tabs are pure CSS (a hidden checkbox and radios +
  `:has()`), so the block needs no hook or Alpine and works in dead views. Code
  is highlighted server-side via the optional `:lumis` dependency, falling back
  to plain code in the same chrome.

      <.code_block id="install" filename="mix.exs" language="elixir" code={@deps} />

      <.code_block id="recipe" files={[
        %{name: "lib/my_app_web/live/chat_live.ex", code: @live},
        %{name: "assets/js/hooks/chat.js", code: @hook}
      ]} />
  """
  def code_block(assigns) do
    files = code_files(assigns)

    if length(files) > @max_files do
      raise ArgumentError,
            "code_block #{inspect(assigns.id)} got #{length(files)} files; it shows at most #{@max_files}"
    end

    multi = length(files) > 1

    assigns =
      assign(assigns,
        files: Enum.with_index(files),
        multi: multi,
        header: multi or Enum.any?(files, & &1.name),
        folds: folds?(assigns.collapsible, files)
      )

    ~H"""
    <div
      id={@id}
      class={[
        "pc-code not-prose",
        @attached && "pc-code--attached",
        @multi && "pc-code--multi",
        @folds && "pc-code--collapsible",
        @locked && "pc-code--locked",
        @wrap && "pc-code--wrap",
        @class
      ]}
    >
      <%!-- Client-side UI state lives in inputs under phx-update="ignore": a
      LiveView patch must not reset an expanded panel or a chosen file, while
      the code itself still patches (the playground heroes rewrite theirs as
      the dials turn). --%>
      <div :if={@folds && !@locked} id={"#{@id}-state"} phx-update="ignore" class="pc-code__state">
        <input
          type="checkbox"
          id={"#{@id}-expand"}
          class="pc-code__expand sr-only"
          aria-label="Show all of the code"
        />
      </div>

      <div :if={@header} class="pc-code__header">
        <div
          :if={@multi}
          id={"#{@id}-tabs"}
          phx-update="ignore"
          class="pc-code__tabs"
          role="radiogroup"
          aria-label="Files"
        >
          <%= for {file, i} <- @files do %>
            <input
              type="radio"
              name={"#{@id}-file"}
              id={"#{@id}-file-#{i}"}
              class="pc-code__radio sr-only"
              data-i={i}
              checked={i == 0}
            />
            <label for={"#{@id}-file-#{i}"} class="pc-code__tab">{file.name || "File #{i + 1}"}</label>
          <% end %>
        </div>
        <div :if={!@multi} class="pc-code__tabs">
          <span :for={{file, _i} <- @files} class="pc-code__label">{file.name}</span>
        </div>
        <div :if={@copy && !@locked} class="pc-code__actions">
          <.code_copy
            :for={{file, i} <- @files}
            id={"#{@id}-copy-#{i}"}
            index={i}
            code={file.code}
            label={file.name}
          />
        </div>
      </div>

      <div class="pc-code__body">
        <div :for={{file, i} <- @files} class="pc-code__pane" data-i={i}>{file.html}</div>

        <.code_copy
          :for={{file, i} <- @files}
          :if={!@header && @copy && !@locked}
          id={"#{@id}-copy-#{i}"}
          index={i}
          code={file.code}
          floating
        />

        <label :if={@folds && !@locked} for={"#{@id}-expand"} class="pc-code__peek">
          <span class="pc-button pc-button--sm pc-code__peek-btn">View code</span>
        </label>

        <div :if={@locked} class="pc-code__lock">
          <%= if @locked_overlay != [] do %>
            {render_slot(@locked_overlay)}
          <% else %>
            <span class="pc-button pc-button--sm pc-code__peek-btn">
              <.icon name="hero-lock-closed-mini" class="size-4" /> Log in to view
            </span>
          <% end %>
        </div>
      </div>
    </div>
    """
  end

  attr :id, :string, required: true
  attr :index, :integer, required: true
  attr :code, :string, required: true
  attr :label, :string, default: nil
  attr :floating, :boolean, default: false

  # Icon mode of the PetalCopy hook: it swaps the default/done spans for a beat.
  defp code_copy(assigns) do
    ~H"""
    <button
      type="button"
      id={@id}
      class={["pc-code__copy", @floating && "pc-code__copy--floating"]}
      data-i={@index}
      phx-hook="PetalCopy"
      data-copy-text={@code}
      title="Copy"
      aria-label={if @label, do: "Copy #{@label}", else: "Copy code"}
    >
      <span data-pc-copy-default><.icon name="hero-square-2-stack" class="size-4" /></span>
      <span data-pc-copy-done class="hidden"><.icon name="hero-check" class="size-4" /></span>
    </button>
    """
  end

  defp code_files(%{files: files} = assigns) when is_list(files) and files != [] do
    Enum.map(files, fn file ->
      file = Map.new(file)
      name = Map.get(file, :name)
      language = Map.get(file, :language) || language_for(name) || assigns.language || "heex"

      code_file(name, Map.get(file, :code) || "", language, Map.get(file, :highlighted))
    end)
  end

  defp code_files(assigns) do
    language = assigns.language || language_for(assigns.filename) || "heex"
    [code_file(assigns.filename, assigns.code || "", language, assigns.highlighted)]
  end

  defp code_file(name, code, language, highlighted) do
    code = String.trim_trailing(code)
    %{name: name, code: code, html: highlighted || code_html(code, language)}
  end

  defp code_html(code, language) do
    Highlight.to_html(code, language) || plain_html(code, language)
  end

  # Same chrome, no colours: the fallback when lumis is absent.
  defp plain_html(code, language) do
    escaped = code |> Phoenix.HTML.html_escape() |> Phoenix.HTML.safe_to_string()
    language = String.replace(language, ~r/[^\w+-]/, "")

    {:safe,
     ~s(<pre class="pc-code__plain"><code class="language-#{language}">#{escaped}</code></pre>)}
  end

  @extensions %{
    ".ex" => "elixir",
    ".exs" => "elixir",
    ".heex" => "heex",
    ".eex" => "eex",
    ".js" => "javascript",
    ".mjs" => "javascript",
    ".ts" => "typescript",
    ".css" => "css",
    ".html" => "html",
    ".json" => "json",
    ".md" => "markdown",
    ".sh" => "bash",
    ".yml" => "yaml",
    ".yaml" => "yaml",
    ".toml" => "toml",
    ".sql" => "sql",
    ".diff" => "diff"
  }

  defp language_for(nil), do: nil
  defp language_for(name), do: Map.get(@extensions, name |> Path.extname() |> String.downcase())

  # Short snippets fit inside the folded height, so there is nothing to reveal.
  defp folds?(:auto, files), do: Enum.any?(files, &(line_count(&1.code) > 5))
  defp folds?(collapsible, _files), do: collapsible == true

  defp line_count(code), do: code |> String.trim() |> String.split("\n") |> length()

  attr :component, :atom,
    required: true,
    doc: "the component module, e.g. PetalComponents.Chat"

  attr :function, :atom, default: nil, doc: "a single component function, e.g. :border_beam"

  attr :functions, :list,
    default: nil,
    doc:
      "several functions to document (one table each) - for multi-function components like chat"

  attr :class, :any, default: nil

  @doc """
  Renders a component's attributes and slots as a table (one per function),
  straight from `Phoenix.Component.__components__/0` - so props docs can never
  drift from the component's real API. Pass `function` for a single-function
  component, or `functions` for a multi-function one (chat, command).
  """
  def showcase_props(assigns) do
    funcs = assigns.functions || List.wrap(assigns.function)
    defs = assigns.component.__components__()

    tables =
      Enum.map(funcs, fn f ->
        info = Map.get(defs, f, %{attrs: [], slots: []})
        %{name: f, attrs: info.attrs, slots: info.slots}
      end)

    assigns = assign(assigns, tables: tables, multi: length(tables) > 1)

    ~H"""
    <div class={["pc-showcase-props not-prose", @class]}>
      <div :for={t <- @tables} class="pc-showcase-props__group">
        <div :if={@multi} class="pc-showcase-props__fn">&lt;.{t.name}&gt;</div>
        <table class="pc-showcase-props__table">
          <thead>
            <tr>
              <th>Attribute</th>
              <th>Type</th>
              <th>Default</th>
              <th>Description</th>
            </tr>
          </thead>
          <tbody>
            <tr :for={a <- t.attrs}>
              <td>
                <code class="pc-showcase-props__name">{a.name}</code><span
                  :if={a.required}
                  class="pc-showcase-props__req"
                  title="required"
                >*</span>
              </td>
              <td><code class="pc-showcase-props__type">{format_type(a.type)}</code></td>
              <td>
                <code :if={Keyword.has_key?(a.opts, :default)} class="pc-showcase-props__default">{inspect(
                  a.opts[:default]
                )}</code>
              </td>
              <td>
                {a.doc}
                <div :if={a.opts[:values]} class="pc-showcase-props__values">
                  one of: {Enum.map_join(a.opts[:values], ", ", &inspect/1)}
                </div>
              </td>
            </tr>
            <tr :for={s <- t.slots}>
              <td>
                <code class="pc-showcase-props__name">:{s.name}</code>
                <span class="pc-showcase-props__slot">slot</span>
              </td>
              <td><code class="pc-showcase-props__type">slot</code></td>
              <td></td>
              <td>{s.doc}</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>
    """
  end

  defp format_type(type) when is_atom(type), do: to_string(type)
  defp format_type(type), do: inspect(type)
end
