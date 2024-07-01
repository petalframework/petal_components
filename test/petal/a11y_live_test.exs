defmodule PetalComponentsWeb.A11yLiveTest do
  @moduledoc """
  A test to load a LiveView using all Petal Components and perform an accessibility audit with `:a11y_audit`.
  `:a11y_audit` uses axe-core under the hood - https://www.deque.com/axe
  """
  use ExUnit.Case, async: true
  use Wallaby.Feature

  feature "components pass a11y_audit", %{session: session} do
    capabilities = Map.get(session, :capabilities)
    capabilities = Map.merge(capabilities, %{javascriptEnabled: true})

    session
    |> Map.put(:capabilities, capabilities)
    |> visit("http://localhost:4000/")
    |> A11yAudit.Wallaby.assert_no_violations()
  end
end
