defmodule PetalComponents.Check.BaselineTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check
  alias PetalComponents.Check.Baseline
  alias PetalComponents.Check.Format
  alias PetalComponents.Check.Rules.ComboboxVariant
  alias PetalComponents.Check.Rules.LiteralNeutral

  defp t, do: Enum.join(["bg", "zinc", "100"], "-")

  setup do
    root = tmp_root()
    on_exit(fn -> File.rm_rf!(root) end)
    %{root: root, bl: Path.join(root, ".petal-check-baseline.json")}
  end

  defp run(root, bl, opts \\ []) do
    {:ok, r} =
      Check.run(
        Keyword.merge(
          [root: root, rules: [LiteralNeutral, ComboboxVariant], baseline: bl, strict: true],
          opts
        )
      )

    r
  end

  defp page(lines_above \\ 0) do
    String.duplicate("<p>pad</p>\n", lines_above) <>
      ~s(<p class="#{t()}"></p>\n<.field type="combobox" variant="input" />\n)
  end

  test "update, then a clean strict run; moving the lines keeps them baselined", %{
    root: root,
    bl: bl
  } do
    write_files(root, %{"lib/a.html.heex" => page()})
    assert run(root, bl).exit_status == 1

    r = run(root, bl, update_baseline: true)
    assert r.exit_status == 0
    assert r.baseline_change.added_count == 2
    text = Enum.join(Format.text(r), "\n")
    assert text =~ "Baseline updated (.petal-check-baseline.json): 2 added, 0 removed, 0 kept."
    assert text =~ "  added: lib/a.html.heex [literal-neutral] #{t()}"

    r = run(root, bl)
    assert r.exit_status == 0
    assert Enum.all?(r.findings, &(&1.status == :baselined))

    write_files(root, %{"lib/a.html.heex" => page(10)})
    assert run(root, bl).exit_status == 0
  end

  test "a second copy of a baselined finding is new", %{root: root, bl: bl} do
    write_files(root, %{"lib/a.html.heex" => page()})
    run(root, bl, update_baseline: true)
    write_files(root, %{"lib/a.html.heex" => page() <> ~s(<p class="#{t()}"></p>\n)})
    r = run(root, bl)
    assert r.exit_status == 1
    # Both copies of the subject are listed; the other key stays baselined.
    assert Enum.count(r.findings, &(&1.status == :new)) == 2
    assert Enum.count(r.findings, &(&1.status == :baselined)) == 1
  end

  test "a new copy added ABOVE a baselined one is named at its own line", %{root: root, bl: bl} do
    write_files(root, %{"lib/a.html.heex" => page(3)})
    run(root, bl, update_baseline: true)

    src = ~s(<p class="#{t()}">new</p>\n) <> page(2)
    write_files(root, %{"lib/a.html.heex" => src})
    r = run(root, bl)
    assert r.exit_status == 1

    new = Enum.filter(r.findings, &(&1.status == :new))
    assert Enum.map(new, & &1.line) == [1, 4]
    assert hd(new).note =~ "this file has 2 copies of #{t()} and the baseline records 1"

    text = Enum.join(Format.text(r), "\n")
    assert text =~ "lib/a.html.heex:1:"
  end

  test "stale entries are counted and pruned, never added", %{root: root, bl: bl} do
    write_files(root, %{"lib/a.html.heex" => page()})
    run(root, bl, update_baseline: true)

    # fix one, add a different new one
    write_files(root, %{
      "lib/a.html.heex" =>
        ~s(<.field type="combobox" variant="input" />\n<p class="dark:#{t()}"></p>\n)
    })

    r = run(root, bl)
    assert r.stale == 1

    assert Enum.join(Format.text(r), "\n") =~
             "1 baseline entry no longer matches (run mix petal.check --prune-baseline to drop it)."

    assert r.exit_status == 1

    r = run(root, bl, prune_baseline: true)
    assert r.baseline_change.removed == 1
    assert r.baseline_change.added_count == 0
    {:ok, entries, true} = Baseline.load(bl, true)
    assert map_size(entries) == 1
    # the new finding is still new: prune never hides it
    assert run(root, bl).exit_status == 1
  end

  test "stale counts only rules that ran", %{root: root, bl: bl} do
    write_files(root, %{"lib/a.html.heex" => page()})
    run(root, bl, update_baseline: true)
    assert run(root, bl, only: ["combobox-variant"]).stale == 0
  end

  test "the file is byte-stable across two updates", %{root: root, bl: bl} do
    write_files(root, %{"lib/a.html.heex" => page(), "lib/b.html.heex" => page()})
    run(root, bl, update_baseline: true)
    first = File.read!(bl)
    run(root, bl, update_baseline: true)
    assert File.read!(bl) == first
    assert {:ok, %{"version" => 1, "entries" => [_, _, _, _]}} = Jason.decode(first)
    refute first =~ "petal_components"
  end

  test "subjects with quotes and backslashes survive" do
    entries = %{{"r", "lib/a b.ex", ~s(name={"hero-" <> @x} \\ ")} => 2}
    text = Baseline.encode(entries)
    root = tmp_root()
    path = Path.join(root, "b.json")
    File.write!(path, text)
    assert {:ok, ^entries, true} = Baseline.load(path, true)
    assert Baseline.encode(entries) == text
    File.rm_rf!(root)
  end

  test "an unchecked file keeps its old entries on update", %{root: root, bl: bl} do
    write_files(root, %{"lib/a.html.heex" => page()})
    run(root, bl, update_baseline: true)
    write_files(root, %{"lib/a.html.heex" => page() <> "<div class=\"oops></div>\n"})
    r = run(root, bl, update_baseline: true)
    assert r.baseline_change.removed == 0
    {:ok, entries, true} = Baseline.load(bl, true)
    assert map_size(entries) == 2
  end

  test "a missing default file is empty; a missing explicit file or a bad file is a usage error",
       %{root: root, bl: bl} do
    assert {:ok, %{}, false} = Baseline.load(bl, false)
    assert {:error, _} = Baseline.load(bl, true)
    File.write!(bl, "{not json")
    assert {:error, msg} = Check.run(root: root, baseline: bl)
    assert msg =~ "is not a petal.check baseline"
  end

  test "no baseline file and errors in two files prints the owner hint", %{root: root, bl: bl} do
    write_files(root, %{"lib/a.html.heex" => page(), "lib/b.html.heex" => page()})
    text = Enum.join(Format.text(run(root, bl)), "\n")

    assert text =~
             "No baseline file. If these findings were already in the app, the app's owner can record them"

    assert text =~ "your agent should not."

    write_files(root, %{"lib/b.html.heex" => "<p></p>\n"})
    refute Enum.join(Format.text(run(root, bl)), "\n") =~ "No baseline file"
  end
end
