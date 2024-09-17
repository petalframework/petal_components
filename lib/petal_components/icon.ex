defmodule PetalComponents.Icon do
  use Phoenix.Component

  require Logger

  deps_paths = Mix.Project.deps_paths()
  heroicons_path = deps_paths[:heroicons]

  # Heroicons aren't available when pushing to hex
  if !heroicons_path do
    attr :rest, :global,
      doc: "the arbitrary HTML attributes for the heroicon container",
      include: ~w(role aria-hidden)

    attr :name, :any, required: true
    attr :class, :any, default: nil, doc: "class applied to heroicon container"

    def icon(%{name: "hero-" <> _} = assigns) do
      ~H"""
      <span class={[@name, @class]} {@rest} />
      """
    end
  end

  # If heroicons are included as a dependency (either in :dev or in the
  # calling application), then generate a function per heroicon variant
  if heroicons_path do
    attr :rest, :global,
      doc: "the arbitrary HTML attributes for the heroicon container",
      include: ~w(role aria-hidden)

    attr :name, :any, required: true
    attr :class, :any, default: nil, doc: "class applied to heroicon container"

    defp heroicon(%{name: "hero-" <> _} = assigns) do
      ~H"""
      <span class={[@name, @class]} {@rest} />
      """
    end

    @icons [
      {"", "/24/outline"},
      {"-solid", "/24/solid"},
      {"-mini", "/20/solid"},
      {"-micro", "/16/solid"}
    ]

    heroicon_names =
      for {suffix, dir} <- @icons do
        path =
          Path.join(heroicons_path, dir)
          |> Path.expand()

        # Read folder
        case File.ls(path) do
          {:ok, file_names} ->
            for file_name <- file_names, do: Path.rootname(file_name) <> suffix

          {:error, _reason} ->
            []
        end
      end
      |> Enum.flat_map(fn x -> x end)

    quote do
      attr :rest, :global,
        doc: "the arbitrary HTML attributes for the svg container",
        include: ~w(role aria-hidden)

      attr :name, :any, required: true
      attr :class, :any, default: nil, doc: "svg class"
    end

    for heroicon_name <- heroicon_names do
      def icon(%{name: "hero-" <> unquote(heroicon_name)} = assigns), do: heroicon(assigns)
    end
  end
end
