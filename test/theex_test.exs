defmodule TheexTest do
  use ExUnit.Case
  doctest Theex

  test "greets the world" do
    assert Theex.hello() == :world
  end
end
