defmodule PetalComponents.Check.PerformanceTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check

  # About three times Petal Pro's HEEx volume. The bound is loose on purpose
  # (shared CI runners); the measured time is printed.
  test "400 files in well under five seconds" do
    root = tmp_root()
    on_exit(fn -> File.rm_rf!(root) end)

    row =
      ~s(<.button phx-click="go" class={["px-2", @on && "font-medium"]} size="sm">Go</.button>\n)

    heex =
      String.duplicate(~s(<div class="flex items-center gap-2">\n  ) <> row <> "</div>\n", 30)

    fun = fn i ->
      "  def f#{i}(assigns) do\n    ~H\"\"\"\n" <> indent(heex) <> "    \"\"\"\n  end\n"
    end

    files =
      for i <- 1..400, into: %{} do
        case rem(i, 4) do
          0 ->
            {"assets/css/f#{i}.css",
             String.duplicate(".a#{i} { @apply p-2 text-sm; color: red; }\n", 40)}

          1 ->
            {"lib/app_web/f#{i}.html.heex", heex}

          _ ->
            {"lib/app_web/f#{i}.ex",
             "defmodule F#{i} do\n  use Phoenix.Component\n" <>
               Enum.map_join(1..3, &fun.(&1)) <> "end\n"}
        end
      end

    write_files(root, files)
    {us, {:ok, report}} = :timer.tc(fn -> Check.run(root: root, no_baseline: true) end)
    IO.puts("\npetal.check performance: #{report.files} files in #{div(us, 1000)} ms")
    assert report.files == 400
    assert report.unchecked == []
    assert us < 5_000_000
  end

  defp indent(text),
    do:
      text |> String.split("\n") |> Enum.map_join("\n", &if(&1 == "", do: "", else: "    " <> &1))
end
