defmodule PetalComponents.MixProject do
  use Mix.Project

  @source_url "https://github.com/petalframework/petal_components"
  @version "1.4.4"

  def project do
    [
      app: :petal_components,
      version: @version,
      elixir: "~> 1.14",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs(),
      aliases: [
        audit: ["format", "credo", "coveralls"]
      ],
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: [
        coveralls: :test,
        "coveralls.detail": :test,
        "coveralls.post": :test,
        "coveralls.html": :test
      ]
    ]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:phoenix, "~> 1.6"},
      {:phoenix_live_view, "~> 0.19"},
      {:jason, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:phoenix_ecto, "~> 4.4"},
      {:credo, "~> 1.6", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:heroicons, "~> 0.5.3"}
    ]
  end

  defp description() do
    """
    Petal is a set of HEEX components that makes it easy for Phoenix developers to start building beautiful web apps.
    """
  end

  defp package do
    [
      maintainers: ["Matt Platts", "Nic Hoban"],
      licenses: ["MIT"],
      links: %{"GitHub" => @source_url},
      files: ~w(mix.exs priv lib assets README.md LICENSE.md CHANGELOG.md)
    ]
  end

  defp docs() do
    [
      main: "readme",
      logo: "logo.png",
      name: "Petal Components",
      source_ref: "v#{@version}",
      canonical: "http://hexdocs.pm/petal_components",
      source_url: @source_url,
      extras: ["README.md"]
    ]
  end
end
