defmodule PetalTest do
  use ExUnit.Case
  doctest Petal

  test "greets the world" do
    assert Petal.hello() == :world
  end
end
