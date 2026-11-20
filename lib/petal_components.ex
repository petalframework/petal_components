defmodule PetalComponents do
  @moduledoc """
  Importing `use PetalComponents` brings the core component set into scope as
  unqualified function components (`<.button>`, `<.modal>`, `<.table>`, …).

  The `PetalComponents.Chat` family (`conversation`, `chat_message`, `markdown`,
  `tool_call`, …) is intentionally **not** part of this import. It defines
  generically-named functions like `markdown/1` that would clash with an app's
  own helpers, so you opt into it explicitly and call it namespaced:

      alias PetalComponents.Chat

      <Chat.conversation id="chat">
        <Chat.chat_message role="assistant"><Chat.markdown content={@text} /></Chat.chat_message>
      </Chat.conversation>

  See the [streaming chat guide](streaming_chat.html) for the full setup.
  """
  # The modules `use PetalComponents` imports. `mix petal.check` reads this
  # same list to know which local calls (`<.button>`) are petal components,
  # so the import and the check cannot drift apart.
  @imported_modules [
    PetalComponents.Accordion,
    PetalComponents.Alert,
    PetalComponents.AlertDialog,
    PetalComponents.Avatar,
    PetalComponents.Badge,
    PetalComponents.Aurora,
    PetalComponents.BorderBeam,
    PetalComponents.BorderPlasma,
    PetalComponents.BrandIcon,
    PetalComponents.Breadcrumbs,
    PetalComponents.Button,
    PetalComponents.ButtonGroup,
    PetalComponents.Calendar,
    PetalComponents.Card,
    PetalComponents.Carousel,
    PetalComponents.Chart,
    PetalComponents.Collapsible,
    PetalComponents.ColorSchemeSwitch,
    PetalComponents.Confetti,
    PetalComponents.Container,
    PetalComponents.ContextMenu,
    PetalComponents.Dropdown,
    PetalComponents.Empty,
    PetalComponents.Field,
    PetalComponents.FileUpload,
    PetalComponents.Filters,
    PetalComponents.Form,
    PetalComponents.HoverCard,
    PetalComponents.Icon,
    PetalComponents.Input,
    PetalComponents.Kbd,
    PetalComponents.ComboBox,
    PetalComponents.DataTable,
    PetalComponents.DatePicker,
    PetalComponents.Command,
    PetalComponents.InputGroup,
    PetalComponents.InputOtp,
    PetalComponents.LanguageSelect,
    PetalComponents.Link,
    PetalComponents.Loading,
    PetalComponents.LocalTime,
    PetalComponents.Marquee,
    PetalComponents.Meteors,
    PetalComponents.Modal,
    PetalComponents.NavigationMenu,
    PetalComponents.NumberField,
    PetalComponents.NumberTicker,
    PetalComponents.Pagination,
    PetalComponents.Popover,
    PetalComponents.Progress,
    PetalComponents.QrCode,
    PetalComponents.Rating,
    PetalComponents.Resizable,
    PetalComponents.ScrollArea,
    PetalComponents.Scrollspy,
    PetalComponents.Separator,
    PetalComponents.Skeleton,
    PetalComponents.Slider,
    PetalComponents.SlideOver,
    PetalComponents.SocialButton,
    PetalComponents.Sortable,
    PetalComponents.Sparkline,
    PetalComponents.ShineBorder,
    PetalComponents.Sidebar,
    PetalComponents.SpotlightCard,
    PetalComponents.Stepper,
    PetalComponents.Table,
    PetalComponents.Timeline,
    PetalComponents.Toast,
    PetalComponents.Tabs,
    PetalComponents.Tree,
    PetalComponents.ToggleGroup,
    PetalComponents.Tooltip,
    PetalComponents.TextAnimation,
    PetalComponents.Typography,
    PetalComponents.UserDropdownMenu,
    PetalComponents.Menu
  ]

  @doc false
  def imported_modules, do: @imported_modules

  defmacro __using__(_) do
    imports = for mod <- @imported_modules, do: quote(do: import(unquote(mod)))

    quote do
      unquote_splicing(imports)

      alias PetalComponents.HeroiconsV1
    end
  end

  # Deprecated: components no longer use Alpine.js — they're LiveView.JS only.
  # Kept for backwards-compatibility; always returns "live_view_js".
  @default_js_lib Application.compile_env(:petal_components, :default_js_lib, "live_view_js")
  def default_js_lib() do
    @default_js_lib
  end
end
