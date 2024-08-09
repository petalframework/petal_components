ExUnit.start()

Application.put_env(:phoenix_live_view, :debug_heex_annotations, false)

# Configure logger to suppress output for :phoenix_playground
Logger.configure(
  level: :warning,
  handle_otp_reports: false,
  handle_sasl_reports: false
)

{:ok, _} = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, "http://localhost:4000")

# we cannot use `PhoenixPlayground.Test` because that is for LiveView tests, not Wallaby (which is required by a11y_audit)
{:ok, phx_playground_pid} =
  PhoenixPlayground.start(
    live: PetalComponentsWeb.A11yLive,
    open_browser: false,
    live_reload: false
  )

# Teardown code
ExUnit.after_suite(fn res ->
  %{failures: no_of_failures} = res
  passed? = no_of_failures == 0
  PhoenixPlaygroundHelper.shutdown()
  PhoenixPlaygroundHelper.exit_processes(phx_playground_pid)
  if passed?, do: :init.stop(0), else: :init.stop(1)
end)
