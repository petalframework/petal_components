defmodule PetalComponents.StepperTest do
  use ComponentCase
  import PetalComponents.Stepper

  @sample_steps [
    %{
      name: "Step 1",
      description: "First step",
      complete?: true,
      active?: false,
      on_click: "step-1"
    },
    %{
      name: "Step 2",
      description: "Second step",
      complete?: true,
      active?: false,
      on_click: "step-2"
    },
    %{
      name: "Step 3",
      description: "Third step",
      complete?: false,
      active?: true,
      on_click: "step-3"
    }
  ]

  describe "basic rendering" do
    test "renders with proper accessibility attributes" do
      assigns = %{sample_steps: @sample_steps}

      html =
        rendered_to_string(~H"""
        <nav aria-label="Progress">
          <.stepper steps={@sample_steps} class="my-8" />
        </nav>
        """)

      assert html =~ "aria-label=\"Progress steps\""
      assert html =~ "role=\"list\""
      assert html =~ "aria-current=\"step\""
      assert html =~ "role=\"listitem\""
    end

    test "renders correct number of steps" do
      assigns = %{sample_steps: @sample_steps}

      html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} />
        """)

      indicators = html |> String.split("pc-stepper__indicator") |> length() |> Kernel.-(1)
      connectors = html |> String.split("pc-stepper__connector ") |> length() |> Kernel.-(1)

      assert indicators == 3
      assert connectors == 2
    end

    test "renders check icons for completed steps" do
      assigns = %{sample_steps: @sample_steps}

      html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} />
        """)

      check_icons = html |> String.split("hero-check-solid") |> length() |> Kernel.-(1)
      completed_steps = @sample_steps |> Enum.count(& &1.complete?)

      assert check_icons == completed_steps
    end

    test "renders step descriptions when provided" do
      assigns = %{sample_steps: @sample_steps}

      html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} />
        """)

      description_count =
        html |> String.split("pc-stepper__description") |> length() |> Kernel.-(1)

      descriptions_provided = @sample_steps |> Enum.count(& &1.description)

      assert description_count == descriptions_provided
    end
  end

  describe "props" do
    test "correctly applies orientation variants" do
      assigns = %{sample_steps: @sample_steps}

      horizontal_html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} orientation="horizontal" />
        """)

      vertical_html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} orientation="vertical" />
        """)

      assert horizontal_html =~ "pc-stepper--horizontal"
      assert vertical_html =~ "pc-stepper--vertical"
    end

    test "label_placement bottom applies only when horizontal" do
      assigns = %{sample_steps: @sample_steps}

      horizontal_html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} label_placement="bottom" />
        """)

      vertical_html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} orientation="vertical" label_placement="bottom" />
        """)

      assert horizontal_html =~ "pc-stepper--labels-bottom"
      refute vertical_html =~ "pc-stepper--labels-bottom"
    end

    test "correctly applies size variants" do
      assigns = %{sample_steps: @sample_steps}

      html_xs =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} size="xs" />
        """)

      html_sm =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} size="sm" />
        """)

      html_md =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} size="md" />
        """)

      html_lg =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} size="lg" />
        """)

      assert html_xs =~ "pc-stepper--xs"
      assert html_sm =~ "pc-stepper--sm"
      assert html_md =~ "pc-stepper--md"
      assert html_lg =~ "pc-stepper--lg"
    end

    test "variant bars paints segments and keeps circles off by default" do
      assigns = %{sample_steps: @sample_steps}

      bars_html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} variant="bars" />
        """)

      default_html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} />
        """)

      assert bars_html =~ "pc-stepper--bars"

      # The numerals stay in the DOM but stop being painted - a 4px segment
      # has no room for a glyph.
      assert bars_html =~ ~s(class="pc-stepper__number sr-only")

      # ...and neither does the tick, which is disc furniture: every step
      # carries a numeral instead, completed ones included.
      refute bars_html =~ "hero-check-solid"

      numbers = bars_html |> String.split("pc-stepper__number") |> length() |> Kernel.-(1)
      assert numbers == length(@sample_steps)

      refute default_html =~ "pc-stepper--bars"
      refute default_html =~ "sr-only"
      assert default_html =~ "hero-check-solid"
    end

    test "bars is horizontal only and outranks label_placement" do
      assigns = %{sample_steps: @sample_steps}

      vertical_html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} orientation="vertical" variant="bars" />
        """)

      bottom_html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} variant="bars" label_placement="bottom" />
        """)

      refute vertical_html =~ "pc-stepper--bars"
      assert vertical_html =~ "hero-check-solid"

      assert bottom_html =~ "pc-stepper--bars"
      refute bottom_html =~ "pc-stepper--labels-bottom"
    end

    test "bars keeps the circles' aria and jump-target contract" do
      assigns = %{sample_steps: @sample_steps}

      bars_html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} variant="bars" />
        """)

      assert bars_html =~ "role=\"list\""
      assert bars_html =~ "role=\"listitem\""
      assert bars_html =~ "aria-current=\"step\""
      assert bars_html =~ "aria-label=\"Step 1: Step 1 (completed)\""
      assert bars_html =~ "aria-label=\"Step 3: Step 3\""
      assert bars_html =~ "phx-click=\"step-1\""
    end

    test "applies custom classes" do
      assigns = %{sample_steps: @sample_steps}

      html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} class="custom-class" />
        """)

      assert html =~ "custom-class"
    end
  end

  describe "step states" do
    test "applies active class to current step" do
      assigns = %{sample_steps: @sample_steps}

      html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} />
        """)

      active_steps = html |> String.split("pc-stepper__node--active") |> length() |> Kernel.-(1)
      expected_active = @sample_steps |> Enum.count(& &1.active?)

      assert active_steps == expected_active
    end

    test "applies complete class to finished steps" do
      assigns = %{sample_steps: @sample_steps}

      html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} />
        """)

      complete_nodes =
        html |> String.split("pc-stepper__node--complete") |> length() |> Kernel.-(1)

      expected_complete = @sample_steps |> Enum.count(& &1.complete?)

      assert complete_nodes == expected_complete
    end

    test "correctly styles connectors between complete steps" do
      assigns = %{sample_steps: @sample_steps}

      html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} />
        """)

      complete_connectors =
        html |> String.split("pc-stepper__connector--complete") |> length() |> Kernel.-(1)

      # Count how many adjacent complete steps we have
      adjacent_complete =
        @sample_steps
        |> Enum.chunk_every(2, 1, :discard)
        |> Enum.count(fn [a, b] -> a.complete? && b.complete? end)

      assert complete_connectors == adjacent_complete
    end
  end

  describe "edge cases" do
    test "handles single step" do
      assigns = %{sample_steps: [@sample_steps |> List.first()]}

      html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} />
        """)

      connectors = html |> String.split("pc-stepper__connector") |> length() |> Kernel.-(1)
      assert connectors == 0, "Single step should not render any connectors"
    end

    test "handles steps without descriptions" do
      steps_without_descriptions =
        Enum.map(@sample_steps, fn step -> Map.delete(step, :description) end)

      assigns = %{sample_steps: steps_without_descriptions}

      html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} />
        """)

      descriptions = html |> String.split("pc-stepper__description") |> length() |> Kernel.-(1)

      assert descriptions == 0,
             "Steps without descriptions should not render description elements"
    end

    test "steps with no name and no description render no content block" do
      nameless =
        Enum.map(@sample_steps, fn step -> Map.drop(step, [:name, :description]) end)

      assigns = %{sample_steps: nameless}

      html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} />
        """)

      # No empty div sitting in the item's gap - the whole block is absent.
      refute html =~ "pc-stepper__content"
      refute html =~ "pc-stepper__title"
      refute html =~ "pc-stepper__description"

      # Still a stepper: circles, connectors, jump targets.
      indicators = html |> String.split("pc-stepper__indicator") |> length() |> Kernel.-(1)
      assert indicators == 3

      # The name was the only thing that hid, so the label falls back to the
      # count and keeps the completed state.
      assert html =~ "aria-label=\"Step 1 (completed)\""
      assert html =~ "aria-label=\"Step 3\""
    end

    test "a nil name is the same as no name, and a name-only step keeps its title" do
      steps = [
        %{name: nil, description: nil, complete?: true, active?: false},
        %{name: "Named", complete?: false, active?: true}
      ]

      assigns = %{sample_steps: steps}

      html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} />
        """)

      content_blocks = html |> String.split("pc-stepper__content") |> length() |> Kernel.-(1)
      assert content_blocks == 1
      assert html =~ "Named"
      refute html =~ "pc-stepper__description"
    end

    test "handles steps without on_click" do
      steps_without_onclick =
        Enum.map(@sample_steps, fn step -> Map.delete(step, :on_click) end)

      assigns = %{sample_steps: steps_without_onclick}

      html =
        rendered_to_string(~H"""
        <.stepper steps={@sample_steps} />
        """)

      refute html =~ "phx-click", "Steps without on_click should not render phx-click attribute"
    end
  end
end
