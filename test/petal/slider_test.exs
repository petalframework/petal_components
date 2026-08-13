defmodule PetalComponents.SliderTest do
  use ComponentCase

  import PetalComponents.Slider

  # LazyHTML helpers. The interesting assertions here are structural (how many
  # inputs, what each one posts, which element carries which percentage), so
  # everything goes through the parsed DOM rather than substring matching.
  defp inputs(html), do: html |> parse_html() |> LazyHTML.query("input[type=range]")

  defp attrs(html, selector, name) do
    html
    |> parse_html()
    |> LazyHTML.query(selector)
    |> LazyHTML.attribute(name)
  end

  defp attr_at(html, selector, name), do: html |> attrs(selector, name) |> List.first()

  describe "single thumb" do
    test "renders one native range input carrying name, id, bounds and value" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider id="vol" name="volume" value={60} min={0} max={100} step={5} />
        """)

      assert Enum.count(inputs(html)) == 1
      assert attr_at(html, "input[type=range]", "name") == "volume"
      assert attr_at(html, "input[type=range]", "id") == "vol_input"
      assert attr_at(html, "input[type=range]", "min") == "0"
      assert attr_at(html, "input[type=range]", "max") == "100"
      assert attr_at(html, "input[type=range]", "step") == "5"
      assert attr_at(html, "input[type=range]", "value") == "60"
      assert_has_class(html, "pc-slider__input")
    end

    test "the wrapper carries the server-rendered fill fraction" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider id="s" name="v" value={25} min={0} max={100} />
        """)

      assert attr_at(html, "#s", "style") =~ "--pc-slider-frac: 0.25"
      refute html =~ "pc-slider--dual"
    end

    test "the fraction is computed against the given bounds, not assumed 0..100" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider id="s" name="year" value={2010} min={1990} max={2030} />
        """)

      assert attr_at(html, "#s", "style") =~ "--pc-slider-frac: 0.5"
    end

    test "a collapsed range paints at the start rather than dividing by zero" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider id="s" name="v" value={5} min={5} max={5} />
        """)

      assert attr_at(html, "#s", "style") =~ "--pc-slider-frac: 0"
      assert attr_at(html, "input[type=range]", "value") == "5"
    end

    test "reversed bounds are ordered before they reach the native input" do
      assigns = %{}

      # The HTML range spec collapses a control whose max is below its min (max
      # becomes min), so emitting the pair as given would pin the browser's
      # thumb at the top while the server painted the fill halfway.
      html =
        rendered_to_string(~H"""
        <.slider id="s" name="v" value={50} min={100} max={0} />
        """)

      assert attr_at(html, "input[type=range]", "min") == "0"
      assert attr_at(html, "input[type=range]", "max") == "100"
      assert attr_at(html, "input[type=range]", "value") == "50"
      assert attr_at(html, "#s", "style") =~ "--pc-slider-frac: 0.5"
    end

    test "a slider with no value at all sits at the lower bound" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider id="s" name="v" min={10} max={20} />
        """)

      assert attr_at(html, "input[type=range]", "value") == "10"
      assert attr_at(html, "#s", "style") =~ "--pc-slider-frac: 0"
    end

    test "string values are parsed; anything unreadable falls back to the lower bound" do
      # Form params arrive as strings, so every one of these is reachable from
      # a plain <.form> round trip.
      cases = [
        {"40", "40"},
        {"2.5", "2.5"},
        {"not a number", "0"},
        {:loud, "0"}
      ]

      for {value, expected} <- cases do
        assigns = %{value: value}

        html =
          rendered_to_string(~H"""
          <.slider name="v" value={@value} min={0} max={100} />
          """)

        assert attr_at(html, "input[type=range]", "value") == expected,
               "value #{inspect(value)} should render as #{expected}"
      end
    end

    test "a value outside the bounds is clamped server-side" do
      assigns = %{}

      high =
        rendered_to_string(~H"""
        <.slider id="s" name="v" value={500} min={0} max={100} />
        """)

      low =
        rendered_to_string(~H"""
        <.slider id="s" name="v" value={-40} min={0} max={100} />
        """)

      assert attr_at(high, "input[type=range]", "value") == "100"
      assert attr_at(low, "input[type=range]", "value") == "0"
    end

    test "takes name, id and value from a form field" do
      assigns = %{field: to_form(%{"volume" => "35"}, as: :mix)[:volume]}

      html =
        rendered_to_string(~H"""
        <.slider field={@field} min={0} max={100} />
        """)

      assert attr_at(html, "input[type=range]", "name") == "mix[volume]"
      assert attr_at(html, "input[type=range]", "value") == "35"
      # The label defaults to the humanised field name.
      assert html =~ "Volume"
    end
  end

  describe "dual thumb" do
    test "renders two inputs posting both form field names, in order" do
      assigns = %{
        min_field: to_form(%{"min" => "200"}, as: :price)[:min],
        max_field: to_form(%{"max" => "800"}, as: :price)[:max]
      }

      html =
        rendered_to_string(~H"""
        <.slider id="p" min_field={@min_field} max_field={@max_field} min={0} max={1000} />
        """)

      assert Enum.count(inputs(html)) == 2
      assert attrs(html, "input[type=range]", "name") == ["price[min]", "price[max]"]
      assert attrs(html, "input[type=range]", "value") == ["200", "800"]
      assert attr_at(html, "input[type=range]", "id") == "p_min"
      assert_has_class(html, "pc-slider--dual")
    end

    test "values plus a name derive both input names" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider id="p" name="price" values={[10, 90]} min={0} max={100} />
        """)

      assert attrs(html, "input[type=range]", "name") == ["price_min", "price_max"]
      assert attrs(html, "input[type=range]", "value") == ["10", "90"]
    end

    test "min_name and max_name override the derived names" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider values={[10, 90]} min_name="from" max_name="to" />
        """)

      assert attrs(html, "input[type=range]", "name") == ["from", "to"]
    end

    test "reversed values render in order rather than painting a negative fill" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider id="p" name="p" values={[90, 10]} min={0} max={100} />
        """)

      assert attrs(html, "input[type=range]", "value") == ["10", "90"]
      assert attr_at(html, "#p", "style") =~ "--pc-slider-frac-min: 0.1"
      assert attr_at(html, "#p", "style") =~ "--pc-slider-frac-max: 0.9"
    end

    test "out-of-bounds values are clamped on both thumbs" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="p" values={[-10, 400]} min={0} max={100} />
        """)

      assert attrs(html, "input[type=range]", "value") == ["0", "100"]
    end

    test "raises when single and dual attrs are mixed" do
      assigns = %{field: to_form(%{"a" => "1"}, as: :f)[:a]}

      assert_raise ArgumentError, ~r/single-thumb `field` and dual-thumb/, fn ->
        rendered_to_string(~H"""
        <.slider field={@field} values={[1, 2]} />
        """)
      end
    end

    test "raises when only one of min_field/max_field is given" do
      assigns = %{field: to_form(%{"a" => "1"}, as: :f)[:a]}

      assert_raise ArgumentError, ~r/needs both `min_field` and `max_field`/, fn ->
        rendered_to_string(~H"""
        <.slider min_field={@field} />
        """)
      end
    end

    test "raises when values and the dual fields are both given" do
      form = to_form(%{"min" => "1", "max" => "9"}, as: :f)
      assigns = %{min_field: form[:min], max_field: form[:max]}

      assert_raise ArgumentError, ~r/both `values` and min_field\/max_field/, fn ->
        rendered_to_string(~H"""
        <.slider min_field={@min_field} max_field={@max_field} values={[1, 9]} />
        """)
      end
    end

    test "dual mode without any name renders nameless inputs rather than guessing" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider values={[10, 90]} min={0} max={100} />
        """)

      assert Enum.count(inputs(html)) == 2
      assert attrs(html, "input[type=range]", "name") == []
    end

    test "a values list that is not a pair falls back to the bounds" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider id="p" name="p" values={[]} min={0} max={100} />
        """)

      assert attrs(html, "input[type=range]", "value") == ["0", "100"]
      assert attr_at(html, "#p", "style") =~ "--pc-slider-frac-min: 0"
      assert attr_at(html, "#p", "style") =~ "--pc-slider-frac-max: 1"
    end

    test "dual fields without an explicit id derive one from the lower field" do
      form = to_form(%{"min" => "10", "max" => "90"}, as: :price)
      assigns = %{min_field: form[:min], max_field: form[:max]}

      html =
        rendered_to_string(~H"""
        <.slider min_field={@min_field} max_field={@max_field} />
        """)

      assert attrs(html, "input[type=range]", "id") == ["price_min_min", "price_min_max"]
    end
  end

  describe "marks" do
    test "renders one tick per mark, positioned by percentage" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider
          name="v"
          value={50}
          min={0}
          max={100}
          marks={[%{value: 0, label: "Min"}, %{value: 50, label: ""}, %{value: 100, label: "Max"}]}
        />
        """)

      assert html |> parse_html() |> LazyHTML.query(".pc-slider__mark") |> Enum.count() == 3
      assert attrs(html, ".pc-slider__mark", "data-pc-slider-mark") == ["0.0", "0.5", "1.0"]

      assert attrs(html, ".pc-slider__mark", "style") == [
               "--pc-slider-at: 0.0",
               "--pc-slider-at: 0.5",
               "--pc-slider-at: 1.0"
             ]

      assert_has_class(html, "pc-slider--marked")
    end

    test "only non-empty labels render, and the tick layer is hidden from AT" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider
          name="v"
          value={50}
          marks={[%{value: 0, label: "Min"}, %{value: 50, label: ""}, %{value: 100, label: "Max"}]}
        />
        """)

      labels = html |> parse_html() |> LazyHTML.query(".pc-slider__mark-label") |> LazyHTML.text()

      assert labels =~ "Min"
      assert labels =~ "Max"
      assert attr_at(html, ".pc-slider__marks", "aria-hidden") == "true"
      assert attr_at(html, ".pc-slider__mark-labels", "aria-hidden") == "true"
    end

    test "marks inside the filled region take the on-primary treatment" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider
          name="v"
          value={50}
          min={0}
          max={100}
          marks={[%{value: 25, label: ""}, %{value: 75, label: ""}]}
        />
        """)

      classes = attrs(html, ".pc-slider__mark", "class")
      assert Enum.at(classes, 0) =~ "pc-slider__mark--filled"
      refute Enum.at(classes, 1) =~ "pc-slider__mark--filled"
    end

    test "in dual mode only the marks between the two thumbs are filled" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider
          name="p"
          values={[30, 70]}
          min={0}
          max={100}
          marks={[
            %{value: 10, label: ""},
            %{value: 30, label: ""},
            %{value: 50, label: ""},
            %{value: 70, label: ""},
            %{value: 90, label: ""}
          ]}
        />
        """)

      filled =
        html
        |> attrs(".pc-slider__mark", "class")
        |> Enum.map(&String.contains?(&1, "pc-slider__mark--filled"))

      # The bounds count as inside the span, matching the fill's own extent.
      assert filled == [false, true, true, true, false]
    end

    test "mark labels are positioned against the track, not the outer wrapper" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="v" value={50} marks={[%{value: 25, label: "Quarter"}]} />
        """)

      doc = parse_html(html)

      # The outer wrapper also carries the header row and stretches to the
      # widest label, so anchoring there put vertical labels off the track by
      # the header's height. The track wrapper's box IS the track's extent.
      assert doc
             |> LazyHTML.query(".pc-slider__track-wrapper .pc-slider__mark-labels")
             |> Enum.count() ==
               1

      assert attr_at(html, ".pc-slider__mark-label", "style") == "--pc-slider-at: 0.25"
      assert_has_class(html, "pc-slider--mark-labels")
    end

    test "ticks without labels do not reserve a label row" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="v" value={50} marks={[%{value: 25, label: ""}]} />
        """)

      refute html =~ "pc-slider__mark-labels"
      refute html =~ "pc-slider--mark-labels"
    end

    test "no marks means no mark layer at all" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="v" value={50} />
        """)

      refute html =~ "pc-slider__mark"
      refute html =~ "pc-slider--marked"
    end
  end

  describe "show_value" do
    test "inline renders the readout in the header row with prefix and suffix" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="v" label="Discount" value={20} show_value="inline" value_suffix="%" />
        """)

      value = html |> parse_html() |> LazyHTML.query(".pc-slider__value") |> LazyHTML.text()
      assert String.trim(value) == "20%"
      refute html =~ "pc-slider__tooltip"
    end

    test "tooltip renders a bubble anchored to the thumb percentage" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="v" value={40} show_value="tooltip" value_prefix="$" />
        """)

      assert attr_at(html, ".pc-slider__tooltip", "style") =~
               "--pc-slider-at: var(--pc-slider-frac)"

      assert attr_at(html, ".pc-slider__tooltip", "aria-hidden") == "true"

      text = html |> parse_html() |> LazyHTML.query(".pc-slider__tooltip") |> LazyHTML.text()
      assert String.trim(text) == "$40"
      refute html =~ "pc-slider__value"
    end

    test "dual tooltip renders one bubble per thumb" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="p" values={[10, 90]} show_value="tooltip" value_prefix="$" />
        """)

      assert html |> parse_html() |> LazyHTML.query(".pc-slider__tooltip") |> Enum.count() == 2
      assert attr_at(html, ".pc-slider__tooltip--min", "style") =~ "var(--pc-slider-frac-min)"
      assert attr_at(html, ".pc-slider__tooltip--max", "style") =~ "var(--pc-slider-frac-max)"
    end

    test "a float value prints without a trailing zero, and keeps a real fraction" do
      assigns = %{}

      whole =
        rendered_to_string(~H"""
        <.slider name="v" value={50.0} show_value="inline" />
        """)

      fractional =
        rendered_to_string(~H"""
        <.slider name="v" value={2.5} min={0} max={10} show_value="inline" />
        """)

      assert whole
             |> parse_html()
             |> LazyHTML.query(".pc-slider__value")
             |> LazyHTML.text()
             |> String.trim() ==
               "50"

      assert fractional
             |> parse_html()
             |> LazyHTML.query(".pc-slider__value")
             |> LazyHTML.text()
             |> String.trim() == "2.5"
    end

    test "dual inline renders a single min to max readout" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="p" values={[10, 90]} show_value="inline" value_prefix="$" />
        """)

      value = html |> parse_html() |> LazyHTML.query(".pc-slider__value") |> LazyHTML.text()
      assert String.trim(value) == "$10 – $90"
    end

    test "none renders neither readout" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="v" value={40} />
        """)

      refute html =~ "pc-slider__tooltip"
      refute html =~ "pc-slider__value"
    end
  end

  describe "orientation, size, state and class" do
    test "orientation and size add their modifier classes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="v" value={10} size="sm" orientation="vertical" />
        """)

      assert_has_class(html, "pc-slider--sm")
      assert_has_class(html, "pc-slider--vertical")

      html =
        rendered_to_string(~H"""
        <.slider name="v" value={10} size="lg" />
        """)

      assert_has_class(html, "pc-slider--lg")
      assert_has_class(html, "pc-slider--horizontal")

      html =
        rendered_to_string(~H"""
        <.slider name="v" value={10} />
        """)

      assert_has_class(html, "pc-slider--md")
    end

    test "disabled disables every input and dims the wrapper" do
      assigns = %{}

      single =
        rendered_to_string(~H"""
        <.slider name="v" value={10} disabled />
        """)

      dual =
        rendered_to_string(~H"""
        <.slider name="p" values={[10, 90]} disabled />
        """)

      assert_has_class(single, "pc-slider--disabled")
      assert attrs(single, "input[type=range]", "disabled") == [""]
      assert attrs(dual, "input[type=range]", "disabled") == ["", ""]

      # And the attribute is absent, not empty, when enabled.
      enabled =
        rendered_to_string(~H"""
        <.slider name="v" value={10} />
        """)

      assert attrs(enabled, "input[type=range]", "disabled") == []
    end

    test "class lands on the wrapper and rest passes through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider id="s" name="v" value={10} class="mt-4" data-testid="vol" />
        """)

      assert attr_at(html, "#s", "class") =~ "mt-4"
      assert attr_at(html, "#s", "data-testid") == "vol"
    end

    test "the wrapper carries the hook and the bounds the hook reads" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider id="s" name="v" value={10} min={5} max={45} value_prefix="$" value_suffix="k" />
        """)

      assert attr_at(html, "#s", "phx-hook") == "PetalSlider"
      assert attr_at(html, "#s", "data-pc-slider-min") == "5"
      assert attr_at(html, "#s", "data-pc-slider-max") == "45"
      assert attr_at(html, "#s", "data-pc-slider-mode") == "single"
      assert attr_at(html, "#s", "data-value-prefix") == "$"
      assert attr_at(html, "#s", "data-value-suffix") == "k"
    end
  end

  describe "accessibility" do
    test "the native input exposes the value range without any ARIA of ours" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="v" label="Volume" value={60} min={0} max={100} />
        """)

      # role/aria-valuenow/valuemin/valuemax come from the native input, so the
      # markup must NOT hand-roll them - min/max/value are what the browser maps.
      assert attr_at(html, "input[type=range]", "min") == "0"
      assert attr_at(html, "input[type=range]", "max") == "100"
      assert attr_at(html, "input[type=range]", "value") == "60"
      refute html =~ "aria-valuenow"
      refute html =~ ~s(role="slider")
    end

    test "the single input gets an accessible name from the label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="v" label="Volume" value={60} />
        """)

      assert attr_at(html, "input[type=range]", "aria-label") == "Volume"
    end

    test "each dual input gets a distinct accessible name" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="p" label="Price" values={[10, 90]} />
        """)

      assert attrs(html, "input[type=range]", "aria-label") == ["Price minimum", "Price maximum"]
    end

    test "an unlabelled slider still names its input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="volume" value={10} />
        """)

      assert attr_at(html, "input[type=range]", "aria-label") == "volume"
    end

    test "a slider with neither label nor name still names its input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider value={10} />
        """)

      assert attr_at(html, "input[type=range]", "aria-label") == "Value"
    end

    test "the visible readout is hidden from AT, which already gets it from the input" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider name="v" label="Volume" value={60} show_value="inline" />
        """)

      # aria-valuenow on the native input is the announcement; the printed
      # number is the same information a second time.
      assert attr_at(html, ".pc-slider__value", "aria-hidden") == "true"
    end

    test "the visible label points at the input it names" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.slider id="s" name="v" label="Volume" value={10} />
        """)

      assert attr_at(html, "label", "for") == "s_input"
    end
  end

  describe "field integration" do
    test "errors on a used field render as standard field errors" do
      form = to_form(%{"v" => "90"}, as: :f)

      assigns = %{
        field: %{form[:v] | errors: [{"must be less than %{count}", [count: 50]}]}
      }

      html =
        rendered_to_string(~H"""
        <.slider field={@field} min={0} max={100} />
        """)

      error = html |> parse_html() |> LazyHTML.query(".pc-form-field-error") |> LazyHTML.text()
      assert String.trim(error) == "must be less than 50"
    end

    test "no error markup when the field has none" do
      assigns = %{field: to_form(%{"v" => "10"}, as: :f)[:v]}

      html =
        rendered_to_string(~H"""
        <.slider field={@field} />
        """)

      refute html =~ "pc-form-field-error"
    end

    test "a plain string error renders as-is" do
      form = to_form(%{"v" => "90"}, as: :f)
      assigns = %{field: %{form[:v] | errors: ["is not available"]}}

      html =
        rendered_to_string(~H"""
        <.slider field={@field} />
        """)

      error = html |> parse_html() |> LazyHTML.query(".pc-form-field-error") |> LazyHTML.text()
      assert String.trim(error) == "is not available"
    end

    test "errors route through the app's configured translator, as <.field> does" do
      # A gettext app wires this once and expects every component to honour it.
      # The slider used to carry its own interpolator and ignore it.
      Application.put_env(
        :petal_components,
        :error_translator_function,
        {__MODULE__, :translate_for_test}
      )

      on_exit(fn -> Application.delete_env(:petal_components, :error_translator_function) end)

      form = to_form(%{"v" => "90"}, as: :f)

      assigns = %{
        field: %{form[:v] | errors: [{"must be less than %{count}", [count: 50]}]}
      }

      html =
        rendered_to_string(~H"""
        <.slider field={@field} min={0} max={100} />
        """)

      error = html |> parse_html() |> LazyHTML.query(".pc-form-field-error") |> LazyHTML.text()
      assert String.trim(error) == "TRANSLATED: must be less than 50"
    end

    test "an un-stringable binding warns and degrades instead of crashing the render" do
      form = to_form(%{"v" => "90"}, as: :f)

      assigns = %{
        field: %{form[:v] | errors: [{"must be under %{limit}", [limit: %{soft: 50}]}]}
      }

      {html, stderr} =
        ExUnit.CaptureIO.with_io(:stderr, fn ->
          rendered_to_string(~H"""
          <.slider field={@field} />
          """)
        end)

      error = html |> parse_html() |> LazyHTML.query(".pc-form-field-error") |> LazyHTML.text()
      assert String.trim(error) == "invalid value"
      assert stderr =~ "error_translator_function"
    end

    test "dual mode merges and de-duplicates the errors from both thumbs" do
      form = to_form(%{"min" => "90", "max" => "10"}, as: :price)
      error = {"is invalid", []}

      assigns = %{
        min_field: %{form[:min] | errors: [error]},
        max_field: %{form[:max] | errors: [error]}
      }

      html =
        rendered_to_string(~H"""
        <.slider min_field={@min_field} max_field={@max_field} />
        """)

      assert html |> parse_html() |> LazyHTML.query(".pc-form-field-error") |> Enum.count() == 1
    end
  end

  @doc false
  def translate_for_test({msg, opts}) do
    "TRANSLATED: " <>
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
  end
end
