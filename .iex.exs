defmodule Run do
  def playground do
    IO.puts("Starting Phoenix Playground...")

    PhoenixPlayground.start(
      live: PetalComponentsWeb.A11yLive,
      open_browser: true,
      live_reload: true
    )
  end

  def dev do
    IO.puts("""
    To start the full dev server with Tailwind CSS, run:

      iex -S mix run dev.exs
    """)
  end
end
