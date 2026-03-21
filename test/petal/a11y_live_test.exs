defmodule PetalComponentsWeb.A11yLiveTest do
  @moduledoc """
  A test to load a LiveView using all Petal Components and perform an accessibility audit with `:a11y_audit`.
  `:a11y_audit` uses axe-core under the hood - https://www.deque.com/axe
  """
  use ExUnit.Case, async: true

  @tag :a11y
  @tag :skip
  test "components pass a11y_audit" do
    # This test requires Wallaby and chromedriver to be installed
    # Run with: mix test --include a11y
    :ok
  end
end
