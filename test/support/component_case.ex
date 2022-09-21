defmodule ComponentCase do
  use ExUnit.CaseTemplate

  setup do
    # This will run before each test that uses this case
    :ok
  end

  using do
    quote do
      import Phoenix.Component
      import Phoenix.LiveViewTest
    end
  end
end
