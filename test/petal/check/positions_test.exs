defmodule PetalComponents.Check.PositionsTest do
  # Columns are what make a fix pasteable, so each way a class string can be
  # written is pinned here, through the literal-neutral rule.
  use PetalComponents.CheckCase, async: true

  alias PetalComponents.Check.Pos
  alias PetalComponents.Check.Rules.LiteralNeutral

  defp t, do: Enum.join(["bg", "zinc", "100"], "-")

  defp pos(kind, src),
    do:
      kind
      |> findings(src, rules: [LiteralNeutral])
      |> Enum.map(&{&1.line, &1.column})
      |> Enum.sort()

  test "a ~H heredoc with indentation" do
    src =
      "defmodule A do\n  def r(assigns) do\n    ~H\"\"\"\n    <div>\n      <p class=\"x #{t()}\">a</p>\n    </div>\n    \"\"\"\n  end\nend\n"

    assert pos(:ex, src) == [{5, 19}]
  end

  test "a ~H''' heredoc" do
    src =
      "defmodule A do\n  def r(assigns) do\n    ~H'''\n    <p class=\"#{t()}\">a</p>\n    '''\n  end\nend\n"

    assert pos(:ex, src) == [{4, 15}]
  end

  test "a single-line ~H with escaped quotes before the token" do
    src =
      "defmodule A do\n  def r(assigns), do: ~H\"<p title=\\\"x\\\" class=\\\"#{t()}\\\">a</p>\"\nend\n"

    assert pos(:ex, src) == [{2, 49}]
  end

  test "a ~H| sigil" do
    src = "defmodule A do\n  def r(assigns), do: ~H|<p class=\"#{t()}\">a</p>|\nend\n"
    assert pos(:ex, src) == [{2, 36}]
  end

  test "a string with escapes before the token" do
    src = "defmodule A do\n  def x, do: \"a\\n\\\"b\\\" \\x41 \\u{1F600} #{t()}\"\nend\n"
    assert pos(:ex, src) == [{2, 39}]
  end

  test "a heredoc string" do
    src =
      "defmodule A do\n  def x do\n    \"\"\"\n    p-2\n      #{t()}\n    \"\"\"\n  end\nend\n"

    assert pos(:ex, src) == [{5, 7}]
  end

  test "interpolation: a token touching it is dropped, the rest keeps its column" do
    src = "defmodule A do\n  def x(h), do: \"text-\#{h}-500 #{t()} \#{h} #{t()}x\"\nend\n"
    assert pos(:ex, src) == [{2, 32}]
  end

  test "a token after an interpolation" do
    src = "defmodule A do\n  def x(h), do: \"p-1 \#{h} #{t()}\"\nend\n"
    assert pos(:ex, src) == [{2, 27}]
  end

  test "a ~w word list" do
    src = "defmodule A do\n  def x, do: ~w(p-2 #{t()})\nend\n"
    assert pos(:ex, src) == [{2, 21}]
  end

  test "a duplicate and a substring each get their own column" do
    src = ~s(<p class="dark:#{t()} #{t()} #{t()}"></p>\n)
    assert pos(:heex, src) == [{1, 11}, {1, 28}, {1, 40}]
  end

  test "a multi-line attr value" do
    src = ~s(<p class="p-2\n   mt-1 #{t()}"></p>\n)
    assert pos(:heex, src) == [{2, 9}]
  end

  test "an attr with spaces around =" do
    src = ~s(<p class = "#{t()}"></p>\n)
    assert pos(:heex, src) == [{1, 13}]
  end

  test "a multi-line class expression" do
    src = "<p class={[\n  \"a\",\n  @x && \"#{t()}\"\n]}></p>\n"
    assert pos(:heex, src) == [{3, 10}]
  end

  test "EEx and body expressions" do
    src = "<%= if @a, do: \"#{t()}\" %>\n<p>{if @b, do: \"#{t()}\"}</p>\n"
    assert pos(:heex, src) == [{1, 17}, {2, 17}]
  end

  test "Pos.walk falls back to :lost when the source disagrees" do
    raw = Pos.lines("abc")
    assert Pos.walk(raw, {1, 1}, "abd") == :lost
    assert Pos.walk(raw, {1, 1}, "ab") == {:ok, {1, 3}}
  end
end
