defmodule PetalComponents.Showcase.Collapsible do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Collapsible,
    title: "Collapsible"

  example :basic, "Show advanced options",
    description:
      "One region, no neighbours. Tab to the trigger and press Enter or Space - it is a real button, so keyboard support is not something the component had to invent." do
    ~H"""
    <div class="max-w-md">
      <.field type="text" name="sx_name" label="Webhook URL" value="https://example.com/hooks" />
      <.collapsible id="sx-collapsible-basic">
        <:trigger>Advanced options</:trigger>
        <div class="space-y-3">
          <.field type="number" name="sx_timeout" label="Timeout (seconds)" value="30" no_margin />
          <.field type="number" name="sx_retries" label="Max retries" value="3" no_margin />
          <.field type="checkbox" name="sx_verify" label="Verify TLS certificate" checked no_margin />
        </div>
      </.collapsible>
    </div>
    """
  end

  example :open, "Open on render",
    description:
      "open is the state the server renders, so LiveView drives it too: re-render with a changed assign and the region follows. The chevron is rotated to match." do
    ~H"""
    <div class="max-w-md">
      <.collapsible id="sx-collapsible-open" open>
        <:trigger>API keys (3)</:trigger>
        <ul class="space-y-2">
          <li class="flex items-center justify-between gap-4">
            <code class="pc-inline-code">pk_live_9f2a…</code>
            <.badge size="sm" color="success" label="active" />
          </li>
          <li class="flex items-center justify-between gap-4">
            <code class="pc-inline-code">pk_live_31cd…</code>
            <.badge size="sm" color="success" label="active" />
          </li>
          <li class="flex items-center justify-between gap-4">
            <code class="pc-inline-code">pk_test_77be…</code>
            <.badge size="sm" color="gray" label="revoked" />
          </li>
        </ul>
      </.collapsible>
    </div>
    """
  end

  example :changelog, "A changelog entry",
    description:
      "Stack them and you get a list of independently collapsible entries - independent is the point. When opening one should close the others, use the accordion instead." do
    ~H"""
    <div class="max-w-md divide-y divide-gray-200 dark:divide-gray-800">
      <.collapsible id="sx-collapsible-log-1">
        <:trigger>
          <span class="flex items-center gap-2">
            4.14.0 <.badge size="sm" color="primary" label="latest" />
          </span>
        </:trigger>
        Added the border_plasma effect: a glowing border that breathes in place, or sweeps a
        conic gradient around the ring.
      </.collapsible>
      <.collapsible id="sx-collapsible-log-2">
        <:trigger>4.13.0</:trigger>
        Fixed the data table's search, page-size and filter forms so their ids stay stable
        across re-renders.
      </.collapsible>
    </div>
    """
  end

  example :disabled, "Disabled",
    description:
      "The native disabled attribute on the button, so it drops out of the tab order and no toggle fires. Use it when the section has nothing in it yet." do
    ~H"""
    <div class="max-w-md">
      <.collapsible id="sx-collapsible-disabled" disabled>
        <:trigger>Archived projects (0)</:trigger>
        Nothing archived yet.
      </.collapsible>
    </div>
    """
  end
end
