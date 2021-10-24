defmodule Petal.MixProject do
  use Mix.Project

  def project do
    [
      app: :petal,
      version: "0.1.0",
      elixir: "~> 1.12",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
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
      {:phoenix, "~> 1.6.2", only: [:dev, :test]},
      {:phoenix_live_view, "~> 0.17.0", only: [:dev, :test]},
      {:jason, "~> 1.0", only: [:dev, :test]}
    ]
  end
end
