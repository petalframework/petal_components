defmodule PetalComponents.CheckCase do
  @moduledoc """
  Helpers for the `mix petal.check` tests. Sources are inline strings: a
  deliberately broken fixture file under test/ would break `mix format`.
  """

  use ExUnit.CaseTemplate

  alias PetalComponents.Check

  using do
    quote do
      import PetalComponents.CheckCase
      @moduletag :petal_check
    end
  end

  @doc """
  Writes `files` (`%{"lib/app/x.ex" => source}`) into a fresh project dir,
  runs the engine on it and returns the report. Options go to Check.run/1;
  the default is no baseline.
  """
  def run_files(files, opts \\ []) do
    root = tmp_root()

    try do
      write_files(root, files)
      {:ok, report} = Check.run(Keyword.merge([root: root, apps: ["."], no_baseline: true], opts))
      report
    after
      File.rm_rf!(root)
    end
  end

  def tmp_root do
    root = Path.join(System.tmp_dir!(), "petal_check_#{System.unique_integer([:positive])}")
    File.mkdir_p!(root)
    root
  end

  def write_files(root, files) do
    for {path, content} <- files do
      abs = Path.join(root, path)
      File.mkdir_p!(Path.dirname(abs))
      File.write!(abs, content)
    end
  end

  @doc """
  Findings (not meta) of one file kind: :ex, :heex or :css. A .heex file
  gets its module beside it (page_module/0), which brings PetalComponents in,
  as a real template's module does.
  """
  def findings(kind, src, opts \\ []) do
    files = %{path_for(kind) => src}
    files = if kind == :heex, do: Map.merge(page_module(), files), else: files
    run_files(files, opts).findings |> Enum.reject(& &1.meta)
  end

  @doc """
  The module of `lib/app_web/page.html.heex`, with `use PetalComponents`, so
  local calls in that template are petal_components calls.
  """
  def page_module, do: with_modules(%{path_for(:heex) => ""}) |> Map.delete(path_for(:heex))

  @doc """
  Adds, for each .heex file in `files`, the module beside it (`a.ex` for
  `a.html.heex`) with `use PetalComponents`, unless `files` already has one.
  """
  def with_modules(files) do
    Enum.reduce(files, files, fn {path, _}, acc ->
      if String.ends_with?(path, ".heex") do
        mod = String.replace(path, ~r/(\.html)?\.heex$/, ".ex")
        Map.put_new(acc, mod, "defmodule AppWeb.Page do\n  use PetalComponents\nend\n")
      else
        acc
      end
    end)
  end

  def path_for(:ex), do: "lib/app_web/page.ex"
  def path_for(:heex), do: "lib/app_web/page.html.heex"
  def path_for(:css), do: "assets/css/app.css"

  @doc """
  Wraps HEEx in a module with a ~H heredoc, like a real component file that
  does `use PetalComponents`.
  """
  def in_module(heex) do
    body =
      heex |> String.split("\n") |> Enum.map_join("\n", &if(&1 == "", do: "", else: "    " <> &1))

    """
    defmodule AppWeb.Page do
      use PetalComponents

      def render(assigns) do
        ~H\"\"\"
    #{body}
        \"\"\"
      end
    end
    """
  end

  @doc "Asserts the finding's subject is the text at its line and column in `src`."
  def assert_at(src, f) do
    line = src |> String.split("\n") |> Enum.at(f.line - 1)
    at = String.slice(line || "", (f.column - 1)..-1//1)

    ExUnit.Assertions.assert(
      String.starts_with?(at, f.subject),
      "#{inspect(f.subject)} is not at #{f.line}:#{f.column}: #{inspect(line)}"
    )

    f
  end

  @doc """
  Applies each finding's replacement to `src` (a span edit at line:column
  over `subject`) and returns the new source. Raises if a subject is not at
  its position, which is the point: the replacement must be pasteable.
  """
  def apply_replacements(src, findings) do
    findings
    |> Enum.filter(&is_binary(&1.replacement))
    |> Enum.sort_by(&{-&1.line, -&1.column})
    |> Enum.reduce(src, fn f, src ->
      lines = String.split(src, "\n")
      line = Enum.at(lines, f.line - 1)
      {before, rest} = String.split_at(line, f.column - 1)

      unless String.starts_with?(rest, f.subject) do
        raise "subject #{inspect(f.subject)} is not at #{f.line}:#{f.column} in #{inspect(line)}"
      end

      new = before <> f.replacement <> String.replace_prefix(rest, f.subject, "")
      lines |> List.replace_at(f.line - 1, new) |> Enum.join("\n")
    end)
  end
end
