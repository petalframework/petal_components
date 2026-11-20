defmodule PetalComponents.Check.FilesTest do
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Files

  setup do
    root = tmp_root()
    on_exit(fn -> File.rm_rf!(root) end)

    write_files(root, %{
      "lib/a.ex" => "",
      "lib/web/b.html.heex" => "",
      "lib/web/notes.md" => "",
      "assets/css/app.css" => "",
      "assets/vendor/x.css" => "",
      "assets/node_modules/y/z.css" => "",
      "lib/deps/c.ex" => "",
      "lib/.hidden/d.ex" => "",
      "test/t.ex" => "",
      "priv/static/app.css" => "",
      "priv/templates/g.ex" => "",
      "deps/petal_components/lib/p.ex" => ""
    })

    %{root: root}
  end

  test "default roots and the always-excluded dirs", %{root: root} do
    {:ok, f} = Files.discover(root: root)
    assert f.checked == ["assets/css/app.css", "lib/a.ex", "lib/web/b.html.heex"]
    assert f.project_css == ["assets/css/app.css"]
    assert f.project_ex == ["lib/a.ex"]
    assert f.skipped == []
  end

  test "umbrella apps", %{root: root} do
    write_files(root, %{
      "apps/one/lib/x.ex" => "",
      "apps/two/assets/css/y.css" => "",
      "apps/two/test/z.ex" => ""
    })

    {:ok, f} = Files.discover(root: root, apps: ["apps/one", "apps/two"])
    assert f.checked == ["apps/one/lib/x.ex", "apps/two/assets/css/y.css"]
  end

  test "petal_components' own source is excluded wherever it sits", %{root: root} do
    write_files(root, %{
      "apps/petal_components/lib/pc.ex" => "",
      "apps/petal_components/assets/default.css" => "",
      "apps/app/lib/x.ex" => ""
    })

    lib = Path.join(root, "apps/petal_components")

    {:ok, f} =
      Files.discover(
        root: root,
        apps: ["apps/app", "apps/petal_components"],
        library_dirs: [Path.join(lib, "lib"), Path.join(lib, "assets")]
      )

    assert f.checked == ["apps/app/lib/x.ex"]
  end

  test "explicit paths: a dir, a file, and the zones that are skipped", %{root: root} do
    {:ok, f} =
      Files.discover(
        root: root,
        paths: [
          "lib/web",
          "assets/css/app.css",
          "test/t.ex",
          "deps/petal_components/lib/p.ex",
          "priv/templates/g.ex"
        ]
      )

    assert f.checked == ["assets/css/app.css", "lib/web/b.html.heex"]

    assert f.skipped == [
             {"test/t.ex", "files under test/ are not checked"},
             {"deps/petal_components/lib/p.ex", "files under deps/ are not checked"},
             {"priv/templates/g.ex", "files under priv/ are not checked"}
           ]

    {:ok, f} =
      Files.discover(
        root: root,
        paths: ["test/t.ex", "./priv/templates/g.ex"],
        include_excluded: true
      )

    assert f.checked == ["priv/templates/g.ex", "test/t.ex"]
  end

  test "a missing path or another extension is a usage error", %{root: root} do
    assert {:error, "lib/nope.ex does not exist"} =
             Files.discover(root: root, paths: ["lib/nope.ex"])

    assert {:error, msg} = Files.discover(root: root, paths: ["lib/web/notes.md"])
    assert msg =~ "is not a .ex, .heex or .css file"
  end

  test "--exclude globs", %{root: root} do
    {:ok, f} = Files.discover(root: root, exclude: ["lib/**/*.heex"])
    assert f.checked == ["assets/css/app.css", "lib/a.ex"]
    assert f.excluded == 1
    {:ok, f} = Files.discover(root: root, exclude: ["lib/web"])
    assert f.checked == ["assets/css/app.css", "lib/a.ex"]
    assert Files.glob_match?("lib/a/b/c.ex", "lib/**/c.ex")
    assert Files.glob_match?("lib/c.ex", "lib/**/c.ex")
    refute Files.glob_match?("lib/a/c.ex", "lib/*.ex")
    assert Files.glob_match?("lib/ab.ex", "lib/a?.ex")
  end

  test "a changed list keeps only files the default roots would scan", %{root: root} do
    {:ok, f} =
      Files.discover(
        root: root,
        changed: ["lib/a.ex", "test/t.ex", "README.md", "lib/gone.ex", "./assets/css/app.css"]
      )

    assert f.checked == ["assets/css/app.css", "lib/a.ex"]
    {:ok, f} = Files.discover(root: root, changed: [])
    assert f.checked == []
  end
end
