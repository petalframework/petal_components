defmodule Mix.Tasks.Petal.CheckTest do
  # Runs the Mix task itself against temporary app directories. Not async:
  # it changes the working directory and swaps the Mix shell.
  use PetalComponents.CheckCase, async: false

  alias Mix.Tasks.Petal.Check, as: Task

  defp t, do: Enum.join(["bg", "zinc", "100"], "-")

  setup do
    root = tmp_root()
    shell = Mix.shell()
    Mix.shell(Mix.Shell.Process)

    on_exit(fn ->
      Mix.shell(shell)
      File.rm_rf!(root)
    end)

    %{root: root}
  end

  defp in_app(root, argv), do: File.cd!(root, fn -> Task.run(argv) end)

  defp output do
    Stream.repeatedly(fn ->
      receive do
        {:mix_shell, :info, [msg]} -> msg
      after
        0 -> nil
      end
    end)
    |> Enum.take_while(& &1)
    |> Enum.join("\n")
  end

  defp bad_page, do: ~s(<p class="#{t()}"></p>\n<.field type="combobox" variant="input" />\n)

  test "a clean app returns normally (exit 0 must not end a Mix alias)", %{root: root} do
    write_files(root, %{"lib/app_web/page.html.heex" => "<p class=\"p-2\"></p>\n"})
    assert in_app(root, ["--strict"]) == :ok
    out = output()
    assert out =~ "petal.check: 1 file (1 with HEEx), 0 unchecked. 0 new errors"
    assert out =~ "petal.check --strict passed (0 suppressed, 0 excluded)."
  end

  test "new errors under --strict exit 1, and each line has the documented shape", %{root: root} do
    write_files(root, %{"lib/app_web/page.html.heex" => bad_page()})
    assert catch_exit(in_app(root, ["--strict", "--no-color"])) == {:shutdown, 1}
    out = output()
    lines = out |> String.split("\n") |> Enum.filter(&String.starts_with?(&1, "lib/"))
    assert length(lines) == 2

    for line <- lines do
      assert line =~ ~r/^[^:]+:\d+:\d+: (error|warning|unchecked) \[[a-z0-9-]+\] .+\. fix: .+$/
    end

    refute out =~ "\e["
    assert out =~ "lib/app_web/page.html.heex:1:11: error [literal-neutral] "
    assert out =~ "petal.check --strict failed: 2 new errors (0 suppressed, 0 excluded)."
    # without --strict the same app exits 0
    assert in_app(root, []) == :ok
  end

  test "an unreadable file under --strict exits 2", %{root: root} do
    write_files(root, %{"lib/broken.ex" => "defmodule B do\n  def x( do\nend\n"})
    assert catch_exit(in_app(root, ["--strict"])) == {:shutdown, 2}

    assert output() =~
             "lib/broken.ex:2:8: unchecked [parse] this file could not be read as Elixir"
  end

  test "usage errors exit 3", %{root: root} do
    for argv <- [
          ["--nope"],
          ["--only", "no-such-rule"],
          ["--format", "xml"],
          ["--only", "literal-neutral", "--except", "literal-neutral"],
          ["lib/missing.ex"],
          ["--update-baseline", "lib"],
          ["--update-baseline", "--except", "literal-neutral"],
          ["--changed", "lib"]
        ] do
      File.mkdir_p!(Path.join(root, "lib"))
      e = assert_raise Mix.Error, fn -> in_app(root, argv) end
      assert e.mix == 3, "#{inspect(argv)} exited #{inspect(e.mix)}"
    end
  end

  test "--format json --output writes one JSON document; stdout gets one line", %{root: root} do
    write_files(root, %{"lib/app_web/page.html.heex" => bad_page()})
    catch_exit(in_app(root, ["--strict", "--format", "json", "--output", "out.json"]))
    out = output()
    assert out =~ "petal.check: report written to out.json (2 new errors, 0 unchecked, exit 1)"
    json = root |> Path.join("out.json") |> File.read!() |> Jason.decode!()
    assert json["version"] == 1
    assert json["summary"]["errors"] == 2
    assert json["exit_status"] == 1
    assert json["options"]["strict"] == true

    assert %{
             "replacement" => ~s(combo_variant="input"),
             "status" => "new",
             "line" => 2,
             "column" => 25
           } =
             Enum.find(json["findings"], &(&1["rule"] == "combobox-variant"))

    assert Enum.map(json["not_checked"], &hd(String.split(&1))) == [
             "11.3",
             "11.6",
             "11.7",
             "11.8",
             "11.13"
           ]

    assert json["tokenizer"] =~ "Tokenizer"
    assert json["phoenix_live_view"] =~ ~r/^\d/
  end

  test "--format json on stdout decodes", %{root: root} do
    write_files(root, %{"lib/app_web/page.html.heex" => "<p></p>\n"})
    assert in_app(root, ["--format", "json"]) == :ok
    assert %{"summary" => %{"files" => 1}} = Jason.decode!(output())
  end

  test "--color forces colour on the severity word", %{root: root} do
    write_files(root, %{"lib/app_web/page.html.heex" => bad_page()})
    in_app(root, ["--color"])
    assert output() =~ IO.ANSI.red() <> "error" <> IO.ANSI.reset()
  end

  test "--help, --rules and --explain", %{root: root} do
    in_app(root, ["--help"])
    assert output() =~ "## For your agent"
    in_app(root, ["--rules"])
    out = output()
    assert out =~ ~r/^combobox-variant\s+error\s+section 11\.9/m
    assert out =~ "literal-neutral"
    in_app(root, ["--explain", "combobox-variant"])
    assert output() =~ "combobox-variant (error, guide section 11.9)"
  end

  test "narrowing is named in the summary", %{root: root} do
    write_files(root, %{
      "lib/app_web/page.html.heex" => bad_page(),
      "lib/app_web/old.html.heex" => "<p></p>\n"
    })

    in_app(root, ["--except", "combobox-variant", "--exclude", "lib/app_web/old.html.heex"])

    assert output() =~
             "Narrowed: rules skipped: combobox-variant (--except); 1 file excluded (--exclude)."
  end

  test "--changed checks changed and untracked files only", %{root: root} do
    write_files(root, %{
      "lib/app_web/old.html.heex" => bad_page(),
      "lib/app_web/edited.html.heex" => "<p></p>\n"
    })

    git = fn args ->
      {_, 0} =
        System.cmd("git", ["-c", "user.email=t@t", "-c", "user.name=t" | args],
          cd: root,
          stderr_to_stdout: true
        )
    end

    git.(["init", "-q"])
    git.(["add", "."])
    git.(["commit", "-q", "-m", "init"])

    assert in_app(root, ["--changed", "--strict"]) == :ok
    assert output() =~ "no changed .ex, .heex or .css files under lib/ or assets/ against HEAD"

    File.write!(Path.join(root, "lib/app_web/edited.html.heex"), bad_page())
    File.write!(Path.join(root, "lib/app_web/new.html.heex"), bad_page())
    File.mkdir_p!(Path.join(root, "test"))
    File.write!(Path.join(root, "test/x.ex"), "")
    catch_exit(in_app(root, ["--changed", "--strict", "--format", "json", "--output", "o.json"]))
    json = root |> Path.join("o.json") |> File.read!() |> Jason.decode!()
    files = json["findings"] |> Enum.map(& &1["file"]) |> Enum.uniq() |> Enum.sort()
    assert files == ["lib/app_web/edited.html.heex", "lib/app_web/new.html.heex"]
    assert json["options"]["changed_against"] == "HEAD"
  end

  test "--update-baseline then a clean strict run", %{root: root} do
    write_files(root, %{"lib/app_web/page.html.heex" => bad_page()})
    assert in_app(root, ["--update-baseline"]) == :ok

    assert output() =~
             "Baseline updated (.petal-check-baseline.json): 2 added, 0 removed, 0 kept."

    assert in_app(root, ["--strict"]) == :ok
    assert output() =~ "2 baselined"
  end
end
