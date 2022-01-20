defmodule PetalComponents.MixProject do
  use Mix.Project

  @source_url "https://github.com/petalframework/petal_components"
  @version "0.9.2"

  def project do
    [
      app: :petal_components,
      version: @version,
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      description: description(),
      package: package(),
      deps: deps(),
      docs: docs()
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
      {:phoenix_live_view, "~> 0.17"},
      {:jason, "~> 1.0", only: [:dev, :test]},
      {:ex_doc, "~> 0.24", only: :dev, runtime: false},
      {:phoenix_ecto, "~> 4.4", only: :test},
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
      links: %{"GitHub" => @source_url}
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
