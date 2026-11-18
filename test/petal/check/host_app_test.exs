defmodule PetalComponents.Check.HostAppTest do
  # The real-library proof, in a separate OS process: a host app with
  # petal_components as a path dependency. Slow (it compiles the library and
  # its runtime deps into the host's _build), so it is excluded by default:
  #
  #     mix test --only slow
  use PetalComponents.CheckCase, async: false

  @moduletag :slow
  @moduletag timeout: 600_000

  test "the task runs without compiling the host; JSON in --output is clean on the first run" do
    repo = File.cwd!()
    root = tmp_root()
    on_exit(fn -> File.rm_rf!(root) end)

    write_files(root, %{
      "mix.exs" => """
      defmodule Host.MixProject do
        use Mix.Project

        def project do
          [
            app: :host,
            version: "0.1.0",
            elixir: "~> 1.14",
            deps: [{:petal_components, path: #{inspect(repo)}}],
            deps_path: #{inspect(Path.join(repo, "deps"))},
            lockfile: #{inspect(Path.join(repo, "mix.lock"))},
            aliases: [chk: ["petal.check --format json --output out.json", &probe/1]]
          ]
        end

        defp probe(_), do: File.write!("probe_ran", "yes")
      end
      """,
      "lib/broken.ex" => "defmodule Broken do\n  def x( do\nend\n",
      "lib/host_web/page.html.heex" => ~s(<.field type="combobox" variant="input" />\n)
    })

    env = [{"MIX_ENV", "dev"}, {"MIX_TEST_PARTITION", nil}]
    {out, status} = System.cmd("mix", ["chk"], cd: root, env: env, stderr_to_stdout: true)
    assert status == 0, out

    # the first run compiled the dependency, and Mix printed that on stdout,
    # which is why the report goes to a file
    json = root |> Path.join("out.json") |> File.read!() |> Jason.decode!()

    assert Enum.any?(
             json["unchecked"],
             &(&1["file"] == "lib/broken.ex" and &1["kind"] == "parse")
           )

    assert Enum.any?(json["findings"], &(&1["rule"] == "combobox-variant"))

    assert File.read!(Path.join(root, "probe_ran")) == "yes",
           "the alias stopped after petal.check"

    refute File.exists?(Path.join(root, "_build/dev/lib/host")), "the host app was compiled"

    {_out, status} =
      System.cmd("mix", ["petal.check", "--strict"], cd: root, env: env, stderr_to_stdout: true)

    assert status == 1
  end
end
