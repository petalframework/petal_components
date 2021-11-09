defmodule PetalComponents.Breadcrumbs do
  use Phoenix.Component
  alias PetalComponents.Heroicons


  # Example:
  # <.breadcrumbs separator="chevron" links={[
  #   %{ label: "Link 1", to: "/" },
  #   %{ label: "Link 1", to: "/", link_type: "patch|a|redirect" }
  # ]}/>
  # prop links, :list
  # prop separator, :string, options: ["slash", "chevron"]
  def breadcrumbs(assigns) do
    assigns = assign_new(assigns, :separator, fn -> "slash" end)

    ~H"""
    <%= for {link, counter} <- Enum.with_index(@links) do %>
      <.breadcrumb {link} separator={if counter > 0, do: @separator} />
    <% end %>
    """
  end

  def breadcrumb(%{link_type: "live_patch"} = assigns) do
    ~H"""
    <%= case @separator do %>
      <% "slash" -> %>
        <div class="px-2 text-gray-500">/</div>
      <% "chevron" -> %>
        <div class="flex items-center px-2 text-gray-500">
          <Heroicons.Solid.chevron_right class="w-5 h-5" />
        </div>
      <% _ -> %>
    <% end %>
    <%= live_patch [
      to: @to,
      class: get_breadcrumb_classes()
    ] do %>
      <%= @label %>
    <% end %>
    """
  end

  def breadcrumb(%{link_type: "live_redirect"} = assigns) do
    ~H"""
    <%= case @separator do %>
      <% "slash" -> %>
        <div class="px-2 text-gray-500">/</div>
      <% "chevron" -> %>
        <div class="flex items-center px-2 text-gray-500">
          <Heroicons.Solid.chevron_right class="w-5 h-5" />
        </div>
      <% _ -> %>
    <% end %>
    <%= live_redirect [
      to: @to,
      class: get_breadcrumb_classes()
    ] do %>
      <%= @label %>
    <% end %>
    """
  end

  def breadcrumb(assigns) do
    ~H"""
    <%= case @separator do %>
      <% "slash" -> %>
        <div class="px-2 text-gray-500">/</div>
      <% "chevron" -> %>
        <div class="flex items-center px-2 text-gray-500">
          <Heroicons.Solid.chevron_right class="w-5 h-5" />
        </div>
      <% _ -> %>
    <% end %>
    <a href={@to} class={get_breadcrumb_classes()}>
      <%= @label %>
    </a>
    """
  end

  def get_breadcrumb_classes(), do: "hover:underline flex text-gray-500"
end
