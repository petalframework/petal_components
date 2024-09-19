defmodule PetalComponents.Icon do
  use Phoenix.Component

  require Logger

  deps_path = Mix.Project.deps_path()
  heroicons_path = Path.join(deps_path, "heroicons/optimized")

  # Heroicons aren't available when pushing to hex
  if !File.dir?(heroicons_path) do
    Logger.warning("""
    Heroicons path "#{heroicons_path}" does not exist or is not a folder. Consider adding the following to your list of dependencies:

    {:heroicons,
      github: "tailwindlabs/heroicons",
      tag: "v2.1.5",
      app: false,
      compile: false,
      sparse: "optimized"}

    See https://petal.build/components/heroicons for up-to-date instructions
    """)

    attr :rest, :global,
      doc: "the arbitrary HTML attributes for the heroicon container",
      include: ~w(role aria-hidden)

    attr :name, :string, required: true
    attr :class, :any, default: nil, doc: "class applied to heroicon container"

    def icon(%{name: name}) when is_atom(name) do
      raise ArgumentError,
        message:
          ":#{name} is not a valid heroicon name. Please use a class name like \"hero-home\""
    end

    def icon(%{name: "hero-" <> _} = assigns) do
      ~H"""
      <span class={[@name, @class]} {@rest} />
      """
    end
  end

  # If heroicons are included as a dependency (either in :dev or in the
  # calling application), then generate a function per heroicon variant
  if File.dir?(heroicons_path) do
    attr :rest, :global,
      doc: "the arbitrary HTML attributes for the heroicon container",
      include: ~w(role aria-hidden)

    attr :name, :string, required: true
    attr :class, :any, default: nil, doc: "class applied to heroicon container"

    defp heroicon(assigns) do
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

      attr :name, :string, required: true
      attr :class, :any, default: nil, doc: "svg class"
    end

    def icon(%{name: name}) when is_atom(name) do
      raise ArgumentError,
        message:
          ":#{name} is not a valid heroicon name. Please use a class name like \"hero-home\""
    end

    for heroicon_name <- heroicon_names do
      def icon(%{name: "hero-" <> unquote(heroicon_name)} = assigns), do: heroicon(assigns)
    end

    def icon(%{name: name}) do
      raise ArgumentError,
        message:
          "\"#{name}\" is not a valid heroicon name. Please use a class name like \"hero-home\", \"hero-home-solid\", \"hero-home-mini\" or \"hero-home-micro\""
    end
  end
end
