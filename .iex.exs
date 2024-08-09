defmodule Run do
  def playground do
    IO.puts("Starting Phoenix Playground...")

    PhoenixPlayground.start(
      live: PetalComponentsWeb.A11yLive,
      open_browser: true,
      live_reload: true
    )
  end
end
