defmodule PetalComponents.RatingTest do
  use ComponentCase
  import PetalComponents.Rating

  test "rating" do
    assigns = %{}

    html =
      rendered_to_string(~H"""
      <.rating include_label rating={3.3} total={5} />
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
      <.rating include_label rating={3.3} total={5} />
      """)

    filled_stars_count =
      html |> String.split("pc-rating__star--filled") |> length() |> Kernel.-(1)

    empty_stars_count = html |> String.split("pc-rating__star--empty") |> length() |> Kernel.-(1)
    half_stars_count = html |> String.split("pc-rating__star--half") |> length() |> Kernel.-(1)

    assert filled_stars_count == 3
    assert empty_stars_count == 1
    assert half_stars_count == 1
  end

  describe "interactive rating" do
    test "renders a radio group with checked value and native form semantics" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.rating interactive name="score" rating={3} />
        """)

      assert html =~ "<fieldset"
      assert html =~ "pc-rating__group"
      assert html =~ "pc-rating--star"
      assert 5 == html |> String.split(~s(type="radio")) |> length() |> Kernel.-(1)
      assert html =~ ~s(name="score")
      assert html =~ ~s(value="3" checked)
      assert html =~ ~s(aria-label="3 of 5")
    end

    test "raises without a name" do
      assigns = %{}

      assert_raise ArgumentError, ~r/requires a name/, fn ->
        rendered_to_string(~H"""
        <.rating interactive rating={2} />
        """)
      end
    end

    test "hearts and sizes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.rating interactive name="love" rating={2} icon="heart" size="lg" total={3} />
        """)

      assert html =~ "pc-rating--heart"
      assert html =~ "pc-rating--lg"
      assert 3 == html |> String.split(~s(type="radio")) |> length() |> Kernel.-(1)
    end

    test "faces are a five-point sentiment scale with named expressions" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.rating interactive name="mood" rating={4} icon="face" total={9} />
        """)

      assert html =~ "pc-rating--face"
      # total is forced to 5 for faces
      assert 5 == html |> String.split(~s(type="radio")) |> length() |> Kernel.-(1)

      for label <- ["Awful", "Bad", "Okay", "Good", "Great"] do
        assert html =~ label
      end
    end

    test "disabled group" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.rating interactive name="score" rating={1} disabled />
        """)

      assert html =~ "pc-rating--disabled"
      assert html =~ "disabled"
    end
  end

  describe "display icon sets" do
    test "hearts fill fractionally via the overlay" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.rating rating={2.5} icon="heart" total={4} />
        """)

      assert html =~ "pc-rating--heart"
      assert html =~ "--pc-rating-fill: 100%"
      assert html =~ "--pc-rating-fill: 50%"
      assert html =~ "--pc-rating-fill: 0%"
    end

    test "custom glyph slot renders per position with the custom modifier" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.rating rating={3} total={5}>
          <:glyph><svg viewBox="0 0 24 24"><path d="M0 0" /></svg></:glyph>
        </.rating>
        """)

      assert html =~ "pc-rating--custom"
      # base + fill overlay copies: 2 per item
      assert 10 == html |> String.split("<svg") |> length() |> Kernel.-(1)
    end

    test "label position bottom and generated face label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.rating rating={4} icon="face" include_label label_position="bottom" />
        """)

      assert html =~ "pc-rating--label-bottom"
      assert html =~ "Good"
      refute html =~ "out of"
    end

    test "faces highlight only the chosen expression" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.rating rating={3} icon="face" />
        """)

      assert html =~ "pc-rating--face"
      assert 1 == html |> String.split(~s(data-selected="true")) |> length() |> Kernel.-(1)
    end
  end
end
