defmodule ComponentCase do
  use ExUnit.CaseTemplate

  setup do
    IO.puts("This will run before each test that uses this case")
  end

  using do
    quote do
      def heex_to_string(template) do
        template
        |> Phoenix.HTML.Safe.to_iodata()
        |> IO.iodata_to_binary()
      end
    end
  end
end
