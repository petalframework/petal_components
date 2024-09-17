defmodule PetalComponents.MixProject do
  use Mix.Project

  @source_url "https://github.com/petalframework/petal_components"
  @version "2.0.0"

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
        wallaby: :test,
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
      {:a11y_audit, "~> 0.2.0", only: :test},
      {:phoenix_playground, "~> 0.1.4", only: [:dev, :test]},
      {:websock_adapter, "~> 0.5.7"},
      {:wallaby, "~> 0.30.9", runtime: false, only: :test},
      {:phoenix, "~> 1.7"},
      {:phoenix_live_view, "~> 0.20"},
      {:phoenix_html, "~> 4.0"},
      {:phoenix_html_helpers, "~> 1.0"},
      {:jason, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:phoenix_ecto, "~> 4.4"},
      {:credo, "~> 1.7", only: [:dev, :test], runtime: false},
      {:excoveralls, "~> 0.10", only: :test},
      {:heroicons,
       github: "tailwindlabs/heroicons",
       tag: "v2.1.5",
       app: false,
       compile: false,
       sparse: "optimized",
       only: [:dev, :test]}
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
