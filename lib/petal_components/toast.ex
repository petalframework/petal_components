defmodule PetalComponents.Toast do
  @moduledoc """
  Toasts with the modern interaction grammar: a collapsed stack that
  expands on hover, per-toast timeout progress, pause on hover, swipe to
  dismiss, and six positions - plus the LiveView-native parts nobody else
  has: server-pushed toasts, id-addressed updates (morph a loading toast
  into a success one), action buttons that push LiveView events, and an
  automatic `put_flash` bridge.

  ## Setup

  Render one group in your root layout (usually just before `</body>`):

      <.toast_group flash={@flash} />

  The `PetalToast` hook ships in the JS bundle (`hooks: { ...PetalComponents }`).

  ## Sending toasts from LiveView

      socket |> Toast.send_toast(:success, title: "Saved", description: "All changes stored.")

      # a sticky loading toast, later morphed by id into a result
      socket |> Toast.send_toast(:loading, id: "export", title: "Exporting...")
      socket |> Toast.send_toast(:success, id: "export", title: "Export ready", duration: 4000)

      # an action button that pushes an event back to your LiveView
      socket
      |> Toast.send_toast(:info,
        title: "Message archived",
        action: %{label: "Undo", event: "undo-archive", value: %{id: msg.id}}
      )

  ## put_flash bridge

  Anything set with `put_flash(:info, ...)` / `put_flash(:error, ...)`
  renders as a toast automatically and the flash is cleared - controllers,
  redirects and old-school flows get modern toasts for free.

  ## From plain JavaScript

      window.dispatchEvent(new CustomEvent("petal:toast", {
        detail: {kind: "success", title: "Copied"}
      }))
  """
  use Phoenix.Component

  @kinds ~w(info success warning danger error loading neutral)a

  @doc """
  Pushes a toast to the client. Returns the socket.

  Options:

    * `:id` - address a toast: pushing again with the same id updates it
      in place (the loading -> success morph)
    * `:title` (required unless updating), `:description`
    * `:duration` - ms before auto-dismiss. Defaults to the group's
      `duration`; `:loading` toasts default to sticky (`:infinity`)
    * `:action` - `%{label: "Undo", event: "undo", value: %{}}` renders a
      button that pushes the event to your LiveView
    * `:closeable` - show the close button (default true)
    * `:progress` - show the timeout progress bar (default true when the
      toast auto-dismisses)
  """
  def send_toast(socket, kind, opts \\ []) when kind in @kinds do
    payload =
      opts
      |> Map.new()
      |> Map.put(:kind, normalize_kind(kind))
      |> Map.update(:duration, nil, fn
        :infinity -> 0
        ms -> ms
      end)

    Phoenix.LiveView.push_event(socket, "petal:toast", payload)
  end

  @doc """
  Dismisses a toast by id, or every toast with `:all` - the retraction
  half of the API. Useful when an async job is cancelled (dismiss the
  loading toast instead of morphing it) or on logout.

      socket |> Toast.dismiss_toast("export")
      socket |> Toast.dismiss_toast(:all)
  """
  def dismiss_toast(socket, id_or_all)

  def dismiss_toast(socket, :all),
    do: Phoenix.LiveView.push_event(socket, "petal:toast-dismiss", %{all: true})

  def dismiss_toast(socket, id),
    do: Phoenix.LiveView.push_event(socket, "petal:toast-dismiss", %{id: to_string(id)})

  defp normalize_kind(:error), do: :danger
  defp normalize_kind(kind), do: kind

  attr :id, :string, default: "pc-toast-group", doc: "one group per layout"

  attr :position, :string,
    default: "bottom-right",
    values: [
      "top-left",
      "top-center",
      "top-right",
      "bottom-left",
      "bottom-center",
      "bottom-right"
    ],
    doc: "where the stack lives"

  attr :max, :integer,
    default: 3,
    doc: "visible toasts while collapsed - the rest queue behind and surface as older ones leave"

  attr :duration, :integer, default: 5000, doc: "default auto-dismiss in ms"

  attr :flash, :map,
    default: nil,
    doc:
      "pass @flash to bridge put_flash into toasts automatically (info and error map to their kinds; the flash is cleared once shown)"

  attr :rest, :global

  @doc """
  The toast mount point. Render once in your root layout.
  """
  def toast_group(assigns) do
    assigns =
      assign(
        assigns,
        :flash_json,
        Phoenix.json_library().encode!(assigns.flash || %{})
      )

    ~H"""
    <div
      id={@id}
      phx-hook="PetalToast"
      data-position={@position}
      data-max={@max}
      data-duration={@duration}
      data-flash={@flash_json}
      class={["pc-toast-group", "pc-toast-group--#{@position}"]}
      role="region"
      aria-label="Notifications"
      {@rest}
    >
      <div id={"#{@id}-stack"} phx-update="ignore" class="pc-toast-group__stack"></div>
    </div>
    """
  end
end
