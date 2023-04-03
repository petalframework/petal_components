defmodule PetalComponents.RatingTest do
  use ComponentCase
  import PetalComponents.Rating

  test "rating" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.rating include_label rating={3.3} total={5}/>
      """)

    assert html =~ "pc-rating__star--filled"
    assert html =~ "pc-rating__star--empty"
    assert html =~ "pc-rating__star--half"
    assert html =~ "pc-rating__label"
  end

  test "correct number of stars rendered based on rating" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.rating include_label rating={3.3} total={5}/>
      """)

    filled_stars_count = html |> String.split("pc-rating__star--filled") |> length() |> Kernel.-(1)
    empty_stars_count = html |> String.split("pc-rating__star--empty") |> length() |> Kernel.-(1)
    half_stars_count = html |> String.split("pc-rating__star--half") |> length() |> Kernel.-(1)

    assert filled_stars_count == 3
    assert empty_stars_count == 1
    assert half_stars_count == 1
  end
end
