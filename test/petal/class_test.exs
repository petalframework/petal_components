defmodule PetalComponents.ClassTest do
  use ExUnit.Case

  import PetalComponents.Class

  test "encode list" do
    assert "some-class extra-class my-class" ==
             build_class(["some-class", "extra-class", "my-class"])
  end

  test "remove whitespace from classes" do
    assert "some-class extra-class my-class" ==
             build_class(["         some-class        ", "extra-class    ", "  my-class"])
  end

  test "remove empty class names" do
    assert "some-class extra-class my-class" ==
             build_class([
               "",
               "some-class",
               "",
               "",
               "",
               "extra-class",
               "",
               "",
               "",
               "",
               "my-class",
               "",
               "",
               "",
               "",
               "",
               "",
               "",
               "",
               "",
               "",
               "",
               "",
               "",
               ""
             ])
  end

  test "remove nil class names" do
    empty_keylist = []

    assert "some-class extra-class my-class" ==
             build_class([
               nil,
               "some-class",
               empty_keylist[:some_key],
               "extra-class",
               nil,
               "my-class",
               nil
             ])
  end
end
