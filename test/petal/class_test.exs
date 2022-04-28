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
end
