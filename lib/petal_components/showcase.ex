defmodule PetalComponents.Showcase do
  @moduledoc """
  Single-source component examples.

  Author each example ONCE as a `~H` block. The `example/3` macro captures the
  block's exact source (for the "View Code" panel) AND compiles it to a render
  function, so the code shown can never drift from the live preview - the whole
  point of the registry. Both the dev playground and petal.build render the same
  `examples/0`, so they stay equivalent by construction.

      defmodule PetalComponents.Showcase.Button do
        use PetalComponents.Showcase, component: PetalComponents.Button, title: "Button"

        example :basic, "Basic", description: "The default button." do
          ~H\"\"\"
          <.button label="Save" />
          \"\"\"
        end
      end

      PetalComponents.Showcase.Button.examples()
      #=> [%PetalComponents.Showcase.Example{id: :basic, title: "Basic",
      #      code: ~s|<.button label="Save" />|, render: #Function<...>, ...}]

  ## Rules for examples

    * The body must be a single `~H` block with no `\#{}` interpolation - examples
      render deterministically with `assigns = %{}` (no outer state, no routes).
    * `id` doubles as the marketing section anchor; keep it stable.
    * Author copy in Matt's voice (no em-dashes, no banned marketing phrases).
  """
  @doc false
  defmacro __using__(opts) do
    quote do
      use Phoenix.Component
      use PetalComponents
      import PetalComponents.Showcase, only: [example: 3, example: 4]

      Module.register_attribute(__MODULE__, :showcase_examples, accumulate: true)
      @showcase_component unquote(opts[:component])
      @showcase_title unquote(opts[:title])
      @before_compile PetalComponents.Showcase
    end
  end

  @doc false
  defmacro __before_compile__(_env) do
    quote do
      @doc "The examples defined in this module, in author order."
      @spec examples() :: [PetalComponents.Showcase.Example.t()]
      def examples do
        @showcase_examples
        |> Enum.reverse()
        |> Enum.map(fn ex ->
          %{ex | render: Function.capture(__MODULE__, :"__showcase_render_#{ex.id}", 1)}
        end)
      end

      @doc "The component module these examples showcase (for the props table), or nil."
      def showcase_component, do: @showcase_component

      @doc "The human title for this component's page."
      def showcase_title, do: @showcase_title
    end
  end

  @doc """
  Defines one example: a stable `id`, a human `title`, optional `description:`,
  and a `do` block that must be a single `~H` sigil.

      example :basic, "Basic" do
        ~H"<.button label=\\"Save\\" />"
      end

      example :danger, "Danger", description: "For destructive actions." do
        ~H"<.button label=\\"Delete\\" color=\\"danger\\" />"
      end
  """
  # With no extra options, the do-block merges into the trailing keyword list.
  defmacro example(id, title, opts) when is_list(opts) do
    {block, meta} = Keyword.pop!(opts, :do)
    __build__(id, title, meta, block)
  end

  # With `description:` (or any option) present, the do-block is a separate arg.
  defmacro example(id, title, opts, do: block) do
    __build__(id, title, opts, block)
  end

  defp __build__(id, title, meta, block) do
    code = __source__(block)
    fun = :"__showcase_render_#{id}"

    quote do
      @showcase_examples %PetalComponents.Showcase.Example{
        id: unquote(id),
        title: unquote(title),
        description: unquote(Keyword.get(meta, :description)),
        code: unquote(code)
      }

      @doc false
      def unquote(fun)(var!(assigns)) do
        _ = var!(assigns)
        unquote(block)
      end
    end
  end

  # Pull the raw source out of a ~H sigil AST. Elixir's heredoc handling has
  # already dedented the block relative to its closing delimiter, so we only
  # trim the surrounding blank lines.
  @doc false
  def __source__({:sigil_H, _meta, [{:<<>>, _, parts}, _mods]}) do
    case parts do
      [raw] when is_binary(raw) ->
        String.trim(raw)

      _ ->
        raise ArgumentError,
              "showcase examples must be static: no interpolation is allowed in the ~H block"
    end
  end

  def __source__(_other) do
    raise ArgumentError, ~S|a showcase example body must be a single ~H"""...""" block|
  end
end
