defmodule PetalComponents.Showcase.Example do
  @moduledoc """
  One showcase example.

    * `id` - atom; on marketing pages this is also the section anchor
    * `title` / `description` - human copy shown above the preview
    * `code` - the exact HEEx source the author wrote (drives the "View Code" panel)
    * `render` - a `(assigns -> rendered)` function that produces the live preview
    * `highlighted` - optional precompiled, syntax-highlighted `{:safe, html}` for
      `code`; `nil` when no highlighter (mdex + lumis) was available at compile time
    * `inert` - render the preview non-interactive (the HTML `inert` attribute).
      For stateful-server examples whose fixed registry values cannot respond to
      clicks - the preview illustrates, the code panel teaches
  """
  @enforce_keys [:id, :title, :code]
  defstruct [:id, :title, :description, :code, :render, :highlighted, inert: false]

  @type t :: %__MODULE__{
          id: atom(),
          title: String.t(),
          description: String.t() | nil,
          code: String.t(),
          render: (map() -> Phoenix.LiveView.Rendered.t()) | nil,
          highlighted: {:safe, iodata()} | nil,
          inert: boolean()
        }
end
