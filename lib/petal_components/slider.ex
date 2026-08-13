defmodule PetalComponents.Slider do
  @moduledoc """
  A styled range slider, in single-thumb and dual-thumb (range) forms.

  Built on native `<input type="range">`. That is the whole accessibility
  story: the browser gives us `role="slider"`, `aria-valuemin`/`valuemax`/
  `valuenow`, the full arrow/Home/End/PageUp/PageDown keyboard map, touch
  and pointer handling, and form posting. None of it is re-implemented here.
  Everything this module adds is paint: a custom track, a primary fill, tick
  marks, and an optional value readout.

  ## Single thumb

      <.slider name="volume" label="Volume" value={60} value_suffix="%" show_value="inline" />

  ## Dual thumb (a range)

  Pass `min_field` and `max_field` (or `values` with `min_name`/`max_name`).
  Two overlaid native inputs post both names, and the fill spans between them.

      <.form for={@form} phx-change="filter">
        <.slider
          min_field={@form[:min]}
          max_field={@form[:max]}
          min={0}
          max={1000}
          step={50}
          label="Price"
          value_prefix="$"
          show_value="inline"
        />
      </.form>

  ## Marks

  `marks` renders labelled stops under the track. An empty label renders a
  tick only, so you can mark every step and label a few.

      <.slider
        name="year"
        label="Year"
        value={2010}
        min={1990}
        max={2030}
        step={5}
        show_value="tooltip"
        marks={[
          %{value: 1990, label: "1990"},
          %{value: 2010, label: "2010"},
          %{value: 2030, label: "2030"}
        ]}
      />

  ## Listening for changes without a form

  Wrapping the slider in a `<.form phx-change="...">` is the usual route, and
  the one the playground's price filter takes. When there is no form to hang it
  on, the `PetalSlider` hook also emits a bubbling `petal:slider-change`
  CustomEvent on the wrapper, carrying `detail: {value}` for a single thumb and
  `detail: {values: [min, max]}` for a dual one:

      // app.js
      window.addEventListener("petal:slider-change", (event) => {
        if (event.target.id !== "volume") return
        document.querySelector("audio").volume = event.detail.value / 100
      })

  It bubbles to `window`, so one listener can serve every slider on the page and
  survives LiveView re-rendering the slider itself.

  ## Relationship to the `range` field types

  `<.field type="range">` and `<.field type="range-dual">` still work and are
  not going anywhere in this release, but `<.slider>` supersedes them: it is
  the same native machinery with marks, a value readout, vertical orientation
  and sizes on top. Reach for `<.slider>` in new code.
  """
  use Phoenix.Component

  alias PetalComponents.Field
  alias Phoenix.HTML.FormField

  attr :field, :any,
    default: nil,
    doc: "a Phoenix.HTML.FormField for single-thumb use; sets name, id and value"

  attr :min_field, :any,
    default: nil,
    doc: "FormField for the lower value; dual-thumb mode when set with max_field"

  attr :max_field, :any,
    default: nil,
    doc: "FormField for the upper value; dual-thumb mode when set with min_field"

  attr :name, :string, default: nil, doc: "input name when not using field"

  attr :min_name, :string,
    default: nil,
    doc: ~s|lower input name in dual mode when not using min_field; defaults to "\#{name}_min"|

  attr :max_name, :string,
    default: nil,
    doc: ~s|upper input name in dual mode when not using max_field; defaults to "\#{name}_max"|

  attr :id, :string, default: nil, doc: "wrapper id; the inputs derive theirs from it"
  attr :value, :any, default: nil, doc: "current value (single-thumb)"

  attr :values, :list,
    default: nil,
    doc: "[min, max] current values (dual-thumb, when not using min_field/max_field)"

  attr :min, :any, default: 0, doc: "lower bound"
  attr :max, :any, default: 100, doc: "upper bound"
  attr :step, :any, default: 1, doc: "step increment; values snap to it natively"

  attr :marks, :list,
    default: [],
    doc:
      ~s|labelled stops rendered under the track, e.g. [%{value: 0, label: "Min"}, %{value: 50, label: ""}]; an empty label renders a tick only|

  attr :show_value, :string,
    default: "none",
    values: ["tooltip", "inline", "none"],
    doc:
      "tooltip shows the value in a bubble above the thumb while dragging or focus-visible; inline renders it in the label row beside the track"

  attr :value_prefix, :string, default: "", doc: ~s|prepended to displayed values, e.g. "$"|
  attr :value_suffix, :string, default: "", doc: ~s|appended to displayed values, e.g. "%"|

  attr :label, :string,
    default: nil,
    doc:
      "visible label above the track, and the base for each input's accessible name (dual thumbs become \"<label> minimum\" and \"<label> maximum\"); defaults to the humanised field name"

  attr :orientation, :string,
    default: "horizontal",
    values: ["horizontal", "vertical"],
    doc: "vertical stands the track up, filling from the bottom"

  attr :size, :string,
    default: "md",
    values: ["sm", "md", "lg"],
    doc: "track thickness and thumb diameter"

  attr :disabled, :boolean, default: false, doc: "disables every input and dims the control"
  attr :class, :any, default: nil, doc: "CSS class for the outer wrapper"
  attr :rest, :global, doc: "any other HTML attributes, applied to the wrapper"

  @doc """
  Renders a slider.

  Single vs dual mode is inferred: `min_field`/`max_field` or `values` means
  dual, otherwise single. Mixing the two raises `ArgumentError`.
  """
  def slider(assigns) do
    assigns
    |> normalise()
    |> render_slider()
  end

  # ---------------------------------------------------------------------------
  # Mode inference and normalisation
  # ---------------------------------------------------------------------------

  defp normalise(assigns) do
    dual? = dual?(assigns)
    validate!(assigns, dual?)

    {lo, hi} = ordered_bounds(to_number(assigns.min, 0), to_number(assigns.max, 100))

    assigns
    |> assign(:dual, dual?)
    |> assign(:lo, lo)
    |> assign(:hi, hi)
    |> assign(:id, assigns.id || default_id(assigns))
    |> assign_label()
    |> assign_values(dual?, lo, hi)
    |> assign_errors(dual?)
    |> assign_marks(lo, hi)
  end

  defp dual?(%{min_field: mf, max_field: xf, values: v}),
    do: not is_nil(mf) or not is_nil(xf) or not is_nil(v)

  # A reversed pair is normalised here rather than only where values are
  # clamped, because `min`/`max` are also written straight onto the native
  # inputs: per the HTML range spec a `max` below `min` collapses the control
  # (max becomes min), so a reversed pair used to paint a sensible fill on the
  # server and then pin the browser's thumb at the top.
  defp ordered_bounds(lo, hi) when lo > hi, do: {hi, lo}
  defp ordered_bounds(lo, hi), do: {lo, hi}

  defp validate!(assigns, true) do
    if assigns.field do
      raise ArgumentError,
            "<.slider> got both a single-thumb `field` and dual-thumb attrs " <>
              "(min_field/max_field/values). Pass one or the other, not both."
    end

    if is_nil(assigns.min_field) != is_nil(assigns.max_field) do
      raise ArgumentError,
            "<.slider> needs both `min_field` and `max_field` for dual-thumb mode, got only one."
    end

    if assigns.values && (assigns.min_field || assigns.max_field) do
      raise ArgumentError,
            "<.slider> got both `values` and min_field/max_field. Pass one or the other."
    end

    :ok
  end

  defp validate!(_assigns, false), do: :ok

  defp default_id(%{field: %FormField{id: id}}), do: id
  defp default_id(%{min_field: %FormField{id: id}}), do: id
  defp default_id(_), do: "pc-slider-#{Ecto.UUID.generate()}"

  defp assign_label(assigns) do
    assign(assigns, :label, assigns.label || derived_label(assigns))
  end

  defp derived_label(%{field: %FormField{field: f}}), do: humanize(f)
  defp derived_label(%{min_field: %FormField{field: f}}), do: humanize(f)
  defp derived_label(_), do: nil

  defp humanize(field), do: PhoenixHTMLHelpers.Form.humanize(field)

  # Accessible name for the inputs. Falls back through label, field name, raw
  # name, then a generic - an input must never be nameless.
  defp a11y_name(assigns) do
    assigns.label || assigns.name || "Value"
  end

  defp assign_values(assigns, true, lo, hi) do
    raw_min = dual_raw(assigns, :min)
    raw_max = dual_raw(assigns, :max)

    min_value = clamp(to_number(raw_min, lo), lo, hi)
    max_value = clamp(to_number(raw_max, hi), lo, hi)

    # Order invariant: a reversed pair renders in order rather than painting a
    # negative fill.
    {min_value, max_value} =
      if min_value > max_value, do: {max_value, min_value}, else: {min_value, max_value}

    assigns
    |> assign(:min_value, min_value)
    |> assign(:max_value, max_value)
    |> assign(:min_frac, frac(min_value, lo, hi))
    |> assign(:max_frac, frac(max_value, lo, hi))
    |> assign(:min_input_name, dual_name(assigns, :min))
    |> assign(:max_input_name, dual_name(assigns, :max))
  end

  defp assign_values(assigns, false, lo, hi) do
    raw = if assigns.field, do: assigns.field.value, else: assigns.value
    value = clamp(to_number(raw, lo), lo, hi)

    assigns
    |> assign(:single_value, value)
    |> assign(:single_frac, frac(value, lo, hi))
    |> assign(:single_name, assigns.name || (assigns.field && assigns.field.name))
  end

  defp dual_raw(%{min_field: %FormField{value: v}}, :min), do: v
  defp dual_raw(%{max_field: %FormField{value: v}}, :max), do: v
  defp dual_raw(%{values: [v, _]}, :min), do: v
  defp dual_raw(%{values: [_, v]}, :max), do: v
  defp dual_raw(_, _), do: nil

  defp dual_name(%{min_field: %FormField{name: n}}, :min), do: n
  defp dual_name(%{max_field: %FormField{name: n}}, :max), do: n
  defp dual_name(%{min_name: n}, :min) when is_binary(n), do: n
  defp dual_name(%{max_name: n}, :max) when is_binary(n), do: n
  defp dual_name(%{name: n}, :min) when is_binary(n), do: n <> "_min"
  defp dual_name(%{name: n}, :max) when is_binary(n), do: n <> "_max"
  defp dual_name(_, _), do: nil

  # Errors come out of the form field(s) and render through the standard field
  # error markup, merged and de-duplicated across both thumbs in dual mode.
  defp assign_errors(assigns, true) do
    assign(
      assigns,
      :errors,
      Enum.uniq(errors_for(assigns.min_field) ++ errors_for(assigns.max_field))
    )
  end

  defp assign_errors(assigns, false) do
    assign(assigns, :errors, errors_for(assigns.field))
  end

  defp errors_for(%FormField{} = field) do
    if Phoenix.Component.used_input?(field) do
      Enum.map(field.errors, &translate_error/1)
    else
      []
    end
  end

  defp errors_for(_), do: []

  # Same translator `<.field>` uses, so an app that has wired
  # `config :petal_components, :error_translator_function` to its gettext
  # helper gets translated slider errors too.
  defp translate_error(error), do: PetalComponents.Helpers.translate_error(error)

  defp assign_marks(assigns, lo, hi) do
    marks =
      Enum.map(assigns.marks, fn mark ->
        value = to_number(Map.get(mark, :value), lo)
        %{value: value, label: Map.get(mark, :label) || "", frac: frac(value, lo, hi)}
      end)

    assigns
    |> assign(:marks, marks)
    |> assign(:has_mark_labels, Enum.any?(marks, &(&1.label != "")))
  end

  # ---------------------------------------------------------------------------
  # Render
  # ---------------------------------------------------------------------------

  defp render_slider(assigns) do
    ~H"""
    <div
      id={@id}
      class={[
        "pc-slider",
        "pc-slider--#{@size}",
        "pc-slider--#{@orientation}",
        @dual && "pc-slider--dual",
        @disabled && "pc-slider--disabled",
        @marks != [] && "pc-slider--marked",
        @has_mark_labels && "pc-slider--mark-labels",
        @class
      ]}
      phx-hook="PetalSlider"
      data-pc-slider-min={@lo}
      data-pc-slider-max={@hi}
      data-pc-slider-mode={if @dual, do: "dual", else: "single"}
      data-value-prefix={@value_prefix}
      data-value-suffix={@value_suffix}
      style={wrapper_style(assigns)}
      {@rest}
    >
      <div :if={@label || @show_value == "inline"} class="pc-slider__header">
        <Field.field_label :if={@label} for={primary_input_id(assigns)} class="pc-slider__label">
          {@label}
        </Field.field_label>
        <span
          :if={@show_value == "inline"}
          class="pc-slider__value"
          data-pc-slider-display
          aria-hidden="true"
        >
          {display_text(assigns)}
        </span>
      </div>

      <div class="pc-slider__track-wrapper">
        <div class="pc-slider__track"></div>
        <div class="pc-slider__fill" data-pc-slider-fill></div>

        <div :if={@marks != []} class="pc-slider__marks" aria-hidden="true">
          <span
            :for={mark <- @marks}
            class={["pc-slider__mark", mark_filled?(assigns, mark) && "pc-slider__mark--filled"]}
            style={"--pc-slider-at: #{mark.frac}"}
            data-pc-slider-mark={mark.frac}
          ></span>
        </div>

        <.slider_inputs {assigns} />

        <div
          :if={@show_value == "tooltip" and not @dual}
          class="pc-slider__tooltip"
          style="--pc-slider-at: var(--pc-slider-frac)"
          data-pc-slider-display
          aria-hidden="true"
        >
          {display_text(assigns)}
        </div>
        <div
          :if={@show_value == "tooltip" and @dual}
          class="pc-slider__tooltip pc-slider__tooltip--min"
          style="--pc-slider-at: var(--pc-slider-frac-min)"
          data-pc-slider-display-min
          aria-hidden="true"
        >
          {format_value(assigns, @min_value)}
        </div>
        <div
          :if={@show_value == "tooltip" and @dual}
          class="pc-slider__tooltip pc-slider__tooltip--max"
          style="--pc-slider-at: var(--pc-slider-frac-max)"
          data-pc-slider-display-max
          aria-hidden="true"
        >
          {format_value(assigns, @max_value)}
        </div>

        <%!-- Inside the track wrapper, not beside it: the labels are positioned
          against the track's box, and the outer wrapper's box also contains the
          header row and stretches to the widest label. Anchored there, every
          vertical label came out offset by the header height and off the track
          centre horizontally. --%>
        <div :if={@has_mark_labels} class="pc-slider__mark-labels" aria-hidden="true">
          <span
            :for={mark <- @marks}
            :if={mark.label != ""}
            class="pc-slider__mark-label"
            style={"--pc-slider-at: #{mark.frac}"}
          >
            {mark.label}
          </span>
        </div>
      </div>

      <Field.field_error :for={msg <- @errors}>{msg}</Field.field_error>
    </div>
    """
  end

  # Private function component: the whole assigns map is forwarded from
  # render_slider/1, so no attr declarations (they would reject the pass-through).
  defp slider_inputs(%{dual: false} = assigns) do
    ~H"""
    <input
      type="range"
      id={@id <> "_input"}
      name={@single_name}
      value={@single_value}
      min={@lo}
      max={@hi}
      step={@step}
      disabled={@disabled}
      aria-label={a11y_name(assigns)}
      class="pc-slider__input"
      data-pc-slider-input
    />
    """
  end

  defp slider_inputs(%{dual: true} = assigns) do
    ~H"""
    <input
      type="range"
      id={@id <> "_min"}
      name={@min_input_name}
      value={@min_value}
      min={@lo}
      max={@hi}
      step={@step}
      disabled={@disabled}
      aria-label={a11y_name(assigns) <> " minimum"}
      class="pc-slider__input pc-slider__input--min"
      data-pc-slider-input-min
    />
    <input
      type="range"
      id={@id <> "_max"}
      name={@max_input_name}
      value={@max_value}
      min={@lo}
      max={@hi}
      step={@step}
      disabled={@disabled}
      aria-label={a11y_name(assigns) <> " maximum"}
      class="pc-slider__input pc-slider__input--max"
      data-pc-slider-input-max
    />
    """
  end

  defp primary_input_id(%{dual: true, id: id}), do: id <> "_min"
  defp primary_input_id(%{id: id}), do: id <> "_input"

  # The fill, the tooltip and every mark anchor off these custom properties, so
  # positioning is pure CSS. Server-rendered here so the control paints
  # correctly before the hook connects (and with JS off entirely); the hook
  # keeps them in sync while dragging.
  defp wrapper_style(%{dual: true} = assigns) do
    "--pc-slider-frac-min: #{assigns.min_frac}; --pc-slider-frac-max: #{assigns.max_frac}"
  end

  defp wrapper_style(assigns) do
    "--pc-slider-frac: #{assigns.single_frac}"
  end

  defp mark_filled?(%{dual: true} = assigns, mark),
    do: mark.value >= assigns.min_value and mark.value <= assigns.max_value

  defp mark_filled?(assigns, mark), do: mark.value <= assigns.single_value

  defp display_text(%{dual: true} = assigns) do
    format_value(assigns, assigns.min_value) <> " – " <> format_value(assigns, assigns.max_value)
  end

  defp display_text(assigns), do: format_value(assigns, assigns.single_value)

  defp format_value(assigns, value) do
    "#{assigns.value_prefix}#{trim_zeros(value)}#{assigns.value_suffix}"
  end

  # 50.0 reads as "50". Mirrors the hook's formatter so server and client agree.
  defp trim_zeros(value) when is_float(value) do
    if value == Float.round(value), do: to_string(round(value)), else: to_string(value)
  end

  defp trim_zeros(value), do: to_string(value)

  # ---------------------------------------------------------------------------
  # Numbers
  # ---------------------------------------------------------------------------

  defp to_number(nil, default), do: default
  defp to_number(v, _default) when is_integer(v) or is_float(v), do: v

  defp to_number(v, default) when is_binary(v) do
    case Integer.parse(v) do
      {int, ""} ->
        int

      _ ->
        case Float.parse(v) do
          {float, ""} -> float
          _ -> default
        end
    end
  end

  defp to_number(_, default), do: default

  defp clamp(value, lo, _hi) when value < lo, do: lo
  defp clamp(value, _lo, hi) when value > hi, do: hi
  defp clamp(value, _lo, _hi), do: value

  # Fractional position of `value` within [lo, hi], 0..1 and unitless.
  #
  # Unitless rather than a percentage because the CSS has to convert it into a
  # thumb-aware offset: a native thumb's centre travels from thumb/2 to
  # width - thumb/2, so anchoring the fill, the tooltip and the ticks at the
  # raw percentage leaves them up to half a thumb adrift at the extremes (a
  # mark at the minimum sits at the very edge of the track while the thumb
  # parked on it sits a radius in). Rounded to 4dp so marks at awkward steps
  # (1990..2030 by 5) land exactly on the tick rather than drifting.
  defp frac(_value, lo, hi) when lo == hi, do: 0
  defp frac(value, lo, hi), do: Float.round((value - lo) / (hi - lo), 4)
end
