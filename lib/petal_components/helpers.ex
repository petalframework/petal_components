defmodule PetalComponents.Helpers do
  @moduledoc """
  For any helper functions used across multiple components. Ideally we keep this empty - components should be copy-pastable.
  """

  alias Phoenix.LiveView.JS

  @doc """
  Translates a changeset error into a displayable message.

  Routes through `config :petal_components, :error_translator_function` when the
  host app has set one (the gettext hook every Phoenix app already wires up for
  `CoreComponents.translate_error/1`), and falls back to plain interpolation of
  the `%{count}`-style bindings otherwise.

  This lives here rather than in a component module because more than one
  component renders field errors, and `PetalComponents.Helpers` is deliberately
  *not* in the `use PetalComponents` import list - a public `translate_error/1`
  in a blanket-imported module would collide with the one nearly every app
  defines in its own web module.
  """
  def translate_error({msg, opts}) do
    case Application.get_env(:petal_components, :error_translator_function) do
      {module, function} -> apply(module, function, [{msg, opts}])
      nil -> fallback_translate_error(msg, opts)
    end
  end

  def translate_error(msg) when is_binary(msg), do: msg

  defp fallback_translate_error(msg, opts) do
    Enum.reduce(opts, msg, fn {key, value}, acc ->
      try do
        String.replace(acc, "%{#{key}}", to_string(value))
      rescue
        e ->
          IO.warn(
            """
            the fallback message translator for the form_field_error function cannot handle the given value.

            Hint: you can set up the `error_translator_function` to route all errors to your application helpers:

              config :petal_components, :error_translator_function, {MyAppWeb.CoreComponents, :translate_error}

            Given value: #{inspect(value)}

            Exception: #{Exception.message(e)}
            """,
            __STACKTRACE__
          )

          "invalid value"
      end
    end)
  end

  @doc """
  Composes two `Phoenix.LiveView.JS` structs by concatenating their operations.
  User JS operations execute first, followed by component JS operations.
  """
  def compose_js(%JS{ops: []}, component_js), do: component_js
  def compose_js(user_js, %JS{ops: []}), do: user_js

  def compose_js(%JS{ops: user_ops}, %JS{ops: component_ops}),
    do: %JS{ops: user_ops ++ component_ops}

  # True when a rendered slot would put nothing but whitespace on the page.
  # Pass it what `render_slot/1` returns, inside the template:
  #
  #     <div :if={!Helpers.blank_render?(render_slot(@inner_block))}>
  #       {render_slot(@inner_block)}
  #     </div>
  #
  # Testing `@inner_block != []` is not enough: an open and close call always
  # carries an inner block, even when it holds only named slots and the
  # whitespace between them. This walks the rendered tree instead, so
  # whitespace, `nil`, empty strings and a false `:if` count as blank. A live
  # component or a comprehension counts as content without being looked into
  # (turning a live component into a string raises), so a slot holding only
  # an empty `:for` still gets its wrapper.
  #
  # Internal for now (@doc false): it can be made public later, but not the
  # other way round.
  @doc false
  def blank_render?(nil), do: true
  def blank_render?(""), do: true
  def blank_render?({:safe, data}), do: blank_render?(data)

  def blank_render?(%Phoenix.LiveView.Rendered{static: static, dynamic: dynamic}) do
    Enum.all?(static, &blank_render?/1) and Enum.all?(dynamic.(false), &blank_render?/1)
  end

  def blank_render?(data) when is_binary(data), do: String.trim(data) == ""

  def blank_render?(data) when is_list(data) do
    data |> IO.iodata_to_binary() |> String.trim() == ""
  rescue
    ArgumentError -> Enum.all?(data, &blank_render?/1)
  end

  def blank_render?(_other), do: false

  @doc """
  Generates a unique HTML ID based on the given string or iodata.

  ## Parameters

    - input: The input string or iodata (e.g., heading or label)
    - prefix: An optional prefix for the ID (default: "c")

  ## Examples

      iex> PetalComponents.Helpers.uniq_id("My Heading")
      "c-my-heading-1234"

      iex> PetalComponents.Helpers.uniq_id(["My ", {:safe, "<a>Link</a>"}, " Label"], "custom")
      "custom-my-link-label-5678"
  """
  def uniq_id(input, prefix \\ "c")

  def uniq_id(input, prefix) when is_list(input) do
    # Convert iodata to string, handling both plain lists and lists with safe HTML
    string =
      input
      |> Enum.map(fn
        {:safe, html} ->
          html
          |> IO.iodata_to_binary()
          |> strip_html_and_entities()

        x when is_binary(x) ->
          x

        x ->
          to_string(x)
      end)
      |> Enum.join("")

    create_slug(string, prefix)
  end

  def uniq_id(string, prefix) when is_binary(string) do
    create_slug(string, prefix)
  end

  def uniq_id(other, prefix) do
    create_slug(to_string(other), prefix)
  end

  defp create_slug(string, prefix) do
    slug =
      string
      |> String.downcase()
      |> String.replace(~r/[^\w-]+/, "-")
      |> String.slice(0, 20)

    unique = System.unique_integer([:positive]) |> Integer.to_string(36)
    "#{prefix}-#{slug}-#{unique}"
  end

  defp strip_html_and_entities(string) do
    string
    # Strip HTML tags
    |> String.replace(~r/<[^>]*>/, " ")
    |> String.replace("&nbsp;", " ")
    |> String.replace("&amp;", "&")
    |> String.replace("&lt;", "<")
    |> String.replace("&gt;", ">")
    |> String.replace("&quot;", "\"")
    |> String.replace("&#39;", "'")
    # Normalize whitespace
    |> String.replace(~r/\s+/, " ")
    |> String.trim()
  end
end
