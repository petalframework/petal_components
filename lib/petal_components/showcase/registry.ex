defmodule PetalComponents.Showcase.Registry do
  @moduledoc """
  The index of every showcase module.

  Hand-maintained (explicit over magic) - a test asserts that every
  `PetalComponents.Showcase.*` example module is listed here, so the list can't
  silently fall out of date. Surfaces use `get/1` to resolve a slug from a route
  and `all/0` to enumerate.
  """

  @modules [
    PetalComponents.Showcase.Accordion,
    PetalComponents.Showcase.Aurora,
    PetalComponents.Showcase.BorderBeam,
    PetalComponents.Showcase.Chat,
    PetalComponents.Showcase.Command
  ]

  @doc "Every showcase module, sorted by title."
  @spec all() :: [module()]
  def all, do: Enum.sort_by(@modules, & &1.showcase_title())

  @doc ~S|The showcase module for a slug (e.g. "border-beam"), or nil.|
  @spec get(String.t() | atom()) :: module() | nil
  def get(slug) do
    slug = to_string(slug)
    Enum.find(@modules, fn mod -> mod.showcase_slug() == slug end)
  end

  @doc "A `{slug, title}` list, handy for building navigation."
  @spec index() :: [{String.t(), String.t()}]
  def index, do: Enum.map(all(), fn mod -> {mod.showcase_slug(), mod.showcase_title()} end)
end
