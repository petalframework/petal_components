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
    PetalComponents.Showcase.Alert,
    PetalComponents.Showcase.Aurora,
    PetalComponents.Showcase.Avatar,
    PetalComponents.Showcase.Badge,
    PetalComponents.Showcase.BorderBeam,
    PetalComponents.Showcase.BorderPlasma,
    PetalComponents.Showcase.Breadcrumbs,
    PetalComponents.Showcase.Button,
    PetalComponents.Showcase.ButtonGroup,
    PetalComponents.Showcase.Card,
    PetalComponents.Showcase.Carousel,
    PetalComponents.Showcase.Chart,
    PetalComponents.Showcase.Chat,
    PetalComponents.Showcase.Collapsible,
    PetalComponents.Showcase.ColorSchemeSwitch,
    PetalComponents.Showcase.ComboBox,
    PetalComponents.Showcase.DataTable,
    PetalComponents.Showcase.Command,
    PetalComponents.Showcase.Confetti,
    PetalComponents.Showcase.ContextMenu,
    PetalComponents.Showcase.Dropdown,
    PetalComponents.Showcase.Empty,
    PetalComponents.Showcase.LanguageSelect,
    PetalComponents.Showcase.SocialButton,
    PetalComponents.Showcase.Field,
    PetalComponents.Showcase.FileUpload,
    PetalComponents.Showcase.InputGroup,
    PetalComponents.Showcase.InputOtp,
    PetalComponents.Showcase.Kbd,
    PetalComponents.Showcase.Loading,
    PetalComponents.Showcase.LocalTime,
    PetalComponents.Showcase.Marquee,
    PetalComponents.Showcase.Meteors,
    PetalComponents.Showcase.Modal,
    PetalComponents.Showcase.NumberField,
    PetalComponents.Showcase.NumberTicker,
    PetalComponents.Showcase.Pagination,
    PetalComponents.Showcase.Popover,
    PetalComponents.Showcase.Progress,
    PetalComponents.Showcase.QrCode,
    PetalComponents.Showcase.Rating,
    PetalComponents.Showcase.ScrollArea,
    PetalComponents.Showcase.Scrollspy,
    PetalComponents.Showcase.Separator,
    PetalComponents.Showcase.ShineBorder,
    PetalComponents.Showcase.Sidebar,
    PetalComponents.Showcase.Skeleton,
    PetalComponents.Showcase.Slider,
    PetalComponents.Showcase.SlideOver,
    PetalComponents.Showcase.Sparkline,
    PetalComponents.Showcase.SpotlightCard,
    PetalComponents.Showcase.Stepper,
    PetalComponents.Showcase.Table,
    PetalComponents.Showcase.Tabs,
    PetalComponents.Showcase.TextAnimation,
    PetalComponents.Showcase.Timeline,
    PetalComponents.Showcase.Toast,
    PetalComponents.Showcase.ToggleGroup,
    PetalComponents.Showcase.Tooltip,
    PetalComponents.Showcase.Tree,
    PetalComponents.Showcase.UserDropdownMenu
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
