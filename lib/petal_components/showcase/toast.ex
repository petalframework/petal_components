defmodule PetalComponents.Showcase.Toast do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Toast,
    title: "Toast",
    functions: [:toast_group]

  alias Phoenix.LiveView.JS

  # No <.toast_group> here on purpose. Toasts are global - LiveView fans
  # push_event out to every mounted group and a window CustomEvent reaches
  # all of them - so a group rendered inside an example would double every
  # toast on a host page that already has one in its layout (a burst of 6
  # dismissing as 12). The example's own description states the rule: one
  # group in the layout catches everything. Hosts rendering this example
  # need that single group; the playground has it, and petal_pro's layout
  # ships with one.
  example :client_toasts, "Fire from anywhere",
    description:
      "One toast_group in the layout catches everything: Toast.send_toast/3 from the server, put_flash for free, or - as here - a plain petal:toast CustomEvent from the client. Fire a few and hover the stack." do
    ~H"""
    <%!-- once, in your root layout: <.toast_group flash={@flash} /> --%>
    <div class="flex flex-wrap items-center justify-center gap-2">
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
