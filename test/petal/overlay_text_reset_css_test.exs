defmodule PetalComponents.OverlayTextResetCssTest do
  use ComponentCase

  import PetalComponents.AlertDialog
  import PetalComponents.Command
  import PetalComponents.ContextMenu
  import PetalComponents.DatePicker
  import PetalComponents.Dropdown
  import PetalComponents.HoverCard
  import PetalComponents.Modal
  import PetalComponents.Popover
  import PetalComponents.SlideOver
  import PetalComponents.Tooltip

  # Every overlay is a DOM child of wherever its call sits, so it inherits
  # that container's text styles: an alert dialog opened from a
  # `<td class="text-right whitespace-nowrap uppercase tabular-nums">` came up
  # right-aligned, unwrapped (a long description ran off the panel), upper
  # case and in tabular figures. The reset puts the container-only text
  # properties back on each surface root. It is pure CSS, so the stylesheet
  # is read here; the markup tests below check that the class each root
  # takes still lands on the element the reset is on, or inside it.

  @app_root Path.expand("../..", __DIR__)

  @roots ~w(
    .pc-alert-dialog
    .pc-command-dialog
    .pc-modal
    .pc-slide-over
    .pc-dropdown__menu-items-wrapper
    .pc-popover__panel
    .pc-context-menu__panel
    .pc-hover-card__panel
    .pc-tooltip__content
    .pc-date-picker__panel
  )

  @reset [
    "text-align: start",
    "white-space: normal",
    "text-transform: none",
    "letter-spacing: normal",
    "font-style: normal",
    "font-variant-numeric: normal",
    "cursor: auto"
  ]

  # Left to inherit on purpose: an app that sets these on body wants them in
  # its overlays too.
  @inherited ~w(font-weight font-size line-height color user-select)

  setup_all do
    css = File.read!(Path.join(@app_root, "assets/default.css"))
    {:ok, %{statements: statements}} = PetalComponents.Check.Css.parse(css)

    rules =
      for st <- statements,
          [selector | _] <- [Enum.reverse(PetalComponents.Check.Css.selectors(st))] do
        %{
          selectors: selector |> String.split(",") |> Enum.map(&String.trim/1),
          layer: PetalComponents.Check.Css.at_rules(st),
          text: st.text,
          line: st.line
        }
      end

    %{rules: rules}
  end

  defp reset_rule(rules) do
    Enum.filter(rules, &(&1.text == "white-space: normal" and ".pc-alert-dialog" in &1.selectors))
  end

  test "the reset is one rule, first in the first @layer components block", %{rules: rules} do
    [first | _] = reset_rule(rules)
    assert first.layer == ["@layer components"]
    assert Enum.sort(first.selectors) == Enum.sort(@roots)

    later =
      Enum.filter(
        rules,
        &(match?(["@layer components" | _], &1.layer) and &1.selectors != first.selectors)
      )

    assert Enum.all?(later, &(&1.line > first.line))
  end

  test "the reset leaves weight, size, line height, colour and selection alone",
       %{rules: rules} do
    [first | _] = reset_rule(rules)
    declared = for r <- rules, r.selectors == first.selectors, do: r.text

    assert Enum.sort(declared) == Enum.sort(@reset)

    for prop <- @inherited do
      refute Enum.any?(declared, &String.starts_with?(&1, prop <> ":")),
             "the overlay reset declares #{prop}"
    end
  end

  for root <- @roots do
    test "#{root} resets the text styles it would inherit from its container", %{rules: rules} do
      declared =
        for r <- rules,
            unquote(root) in r.selectors,
            match?(["@layer components" | _], r.layer),
            do: r.text

      for decl <- @reset do
        assert decl in declared, "#{unquote(root)} does not declare `#{decl}`"
      end
    end

    test "#{root}'s reset comes before the component's own rules, so they still win",
         %{rules: rules} do
      reset_lines =
        rules
        |> Enum.filter(&(unquote(root) in &1.selectors and &1.text == "white-space: normal"))
        |> Enum.map(& &1.line)

      assert reset_lines != [], "#{unquote(root)} has no reset"
      reset_line = Enum.min(reset_lines)

      own =
        Enum.filter(
          rules,
          &(&1.selectors == [unquote(root)] and &1.text != "white-space: normal")
        )

      assert own != [], "no rule of #{unquote(root)}'s own found"
      assert Enum.all?(own, &(&1.line > reset_line))
    end
  end

  test "the combo box panel is not in the reset (another change owns it)", %{rules: rules} do
    refute Enum.any?(
             rules,
             &(".pc-combo-box__panel" in &1.selectors and &1.text == "cursor: auto")
           )
  end

  describe "a class on the component still reaches the reset element" do
    test "alert_dialog class lands on the dialog itself" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.alert_dialog id="del" title="Delete this row?" class="text-right" />
        """)

      assert_classed(html, "dialog#del", "pc-alert-dialog")
      assert_classed(html, "dialog#del", "text-right")
    end

    test "popover panel_class lands on the panel, in both modes" do
      for top_layer <- [false, true] do
        assigns = %{top_layer: top_layer}

        html =
          rendered_to_string(~H"""
          <.popover id="pop" panel_class="uppercase" top_layer={@top_layer}>
            <:trigger>Open</:trigger>
            Body
          </.popover>
          """)

        assert_classed(html, "#pop", "pc-popover__panel")
        assert_classed(html, "#pop", "uppercase")
        refute_classed(html, ".pc-popover", "pc-popover__panel")
      end
    end

    test "dropdown menu_items_wrapper_class lands on the menu wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.dropdown label="Actions" menu_items_wrapper_class="whitespace-nowrap">
          <.dropdown_menu_item label="Edit" />
        </.dropdown>
        """)

      assert_classed(html, "[role=menu]", "pc-dropdown__menu-items-wrapper")
      assert_classed(html, "[role=menu]", "whitespace-nowrap")
    end

    test "date_picker panel_class lands on the panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.date_picker id="dp" name="due_on" panel_class="text-right" />
        """)

      assert_classed(html, ".pc-date-picker__panel", "text-right")
    end

    test "modal class lands on the box inside the reset element, which inherits from it" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.modal id="m" class="text-right">Body</.modal>
        """)

      assert_classed(html, ".pc-modal .pc-modal__box", "text-right")
    end

    test "slide_over class lands inside the reset element" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slide_over id="so" class="text-right">Body</.slide_over>
        """)

      assert_classed(html, ".pc-slide-over [role=dialog]", "text-right")
    end

    test "command_dialog class lands on the palette inside the dialog" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.command_dialog id="cmdk" class="text-right">
          <.command_list>Items</.command_list>
        </.command_dialog>
        """)

      assert_classed(html, "dialog.pc-command-dialog #cmdk-palette", "text-right")
    end

    test "tooltip content_class lands on the bubble" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.tooltip label="Hi" content_class="uppercase">Trigger</.tooltip>
        """)

      assert_classed(html, ".pc-tooltip__content", "uppercase")
    end

    test "hover_card card_class lands on the panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.hover_card card_class="uppercase">
          <:trigger>Name</:trigger>
          Card
        </.hover_card>
        """)

      assert_classed(html, ".pc-hover-card__panel", "uppercase")
    end

    test "context_menu menu_class lands on the panel" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.context_menu id="cm" menu_class="uppercase">
          <:trigger>Area</:trigger>
          <.context_menu_item label="Copy" />
        </.context_menu>
        """)

      assert_classed(html, ".pc-context-menu__panel", "uppercase")
    end
  end

  # The changelog warns about these: on five overlays `class` goes on the
  # outer wrapper, outside the reset, so a text class there stops reaching
  # the panel. If one of them moves `class` onto the panel, change the
  # changelog and usage notes with it.
  describe "a wrapper class sits outside the reset element" do
    test "tooltip, popover, dropdown, hover_card and date_picker" do
      assigns = %{}

      cases = [
        {rendered_to_string(~H"""
         <.tooltip label="Hi" class="uppercase">Trigger</.tooltip>
         """), ".pc-tooltip", ".pc-tooltip__content"},
        {rendered_to_string(~H"""
         <.popover id="pop" class="uppercase">
           <:trigger>Open</:trigger>
           Body
         </.popover>
         """), ".pc-popover", ".pc-popover__panel"},
        {rendered_to_string(~H"""
         <.dropdown label="Actions" class="uppercase">
           <.dropdown_menu_item label="Edit" />
         </.dropdown>
         """), ".pc-dropdown", ".pc-dropdown__menu-items-wrapper"},
        {rendered_to_string(~H"""
         <.hover_card class="uppercase">
           <:trigger>Name</:trigger>
           Card
         </.hover_card>
         """), ".pc-hover-card", ".pc-hover-card__panel"},
        {rendered_to_string(~H"""
         <.date_picker id="dp" name="due_on" class="uppercase" />
         """), ".pc-date-picker", ".pc-date-picker__panel"}
      ]

      for {html, wrapper, panel} <- cases do
        assert_classed(html, wrapper, "uppercase")
        assert classes_of(html, "#{wrapper} #{panel}") != [], "#{panel} is not inside #{wrapper}"
        refute_classed(html, panel, "uppercase")
      end
    end
  end

  defp assert_classed(html, selector, class) do
    classes = classes_of(html, selector)

    assert classes != [], "nothing matches #{selector}"
    assert Enum.all?(classes, &(class in &1)), "#{selector} lacks #{class}: #{inspect(classes)}"
  end

  defp refute_classed(html, selector, class) do
    refute Enum.any?(classes_of(html, selector), &(class in &1))
  end

  defp classes_of(html, selector) do
    html
    |> LazyHTML.from_fragment()
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute("class")
    |> Enum.map(&String.split/1)
  end
end
