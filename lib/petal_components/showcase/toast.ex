defmodule PetalComponents.Showcase.Toast do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Toast, title: "Toast"

  alias Phoenix.LiveView.JS

  example :client_toasts, "Fire from anywhere",
    description:
      "One toast_group in the layout catches everything: Toast.send_toast/3 from the server, put_flash for free, or - as here - a plain petal:toast CustomEvent from the client. Fire a few and hover the stack." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-2">
      <.toast_group id="showcase-toasts" />

      <.button
        color="gray"
        variant="outline"
        phx-click={
          JS.dispatch("petal:toast",
            detail: %{
              kind: "success",
              title: "Changes saved",
              description: "Your profile is up to date."
            }
          )
        }
      >
        Success
      </.button>
      <.button
        color="gray"
        variant="outline"
        phx-click={
          JS.dispatch("petal:toast",
            detail: %{kind: "danger", title: "Export failed", description: "The server returned 500."}
          )
        }
      >
        Danger
      </.button>
      <.button
        color="gray"
        variant="outline"
        phx-click={JS.dispatch("petal:toast", detail: %{kind: "info", title: "Deploy started"})}
      >
        Info
      </.button>
    </div>
    """
  end
end
