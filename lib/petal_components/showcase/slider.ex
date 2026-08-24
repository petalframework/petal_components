defmodule PetalComponents.Showcase.Slider do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Slider, title: "Slider"

  example :basic, "Single thumb",
    description:
      "A native range input with the track, fill and thumb painted by the library, so it looks the same on every browser and OS. label names it for screen readers and prints above the track; show_value=\"inline\" puts the live readout in that same row, with value_prefix and value_suffix formatting it." do
    ~H"""
    <div class="w-full max-w-sm space-y-8">
      <.slider name="volume" label="Volume" value={60} value_suffix="%" show_value="inline" />
      <.slider name="quality" label="Quality" value={3} min={1} max={5} />
    </div>
    """
  end

  example :dual, "Dual thumb",
    description:
      "min_field and max_field make it a range: two thumbs, two form values, one fill spanning between them. Each thumb posts its own name, so a price filter is a plain form change event with no JavaScript of your own. Reversed or out-of-bounds values are clamped and ordered server-side, so the fill can never paint backwards." do
    ~H"""
    <div class="w-full max-w-sm">
      <.slider
        min_field={to_form(%{"min" => "250"}, as: :price)[:min]}
        max_field={to_form(%{"max" => "750"}, as: :price)[:max]}
        min={0}
        max={1000}
        step={50}
        label="Price"
        value_prefix="$"
        show_value="inline"
      />
    </div>
    """
  end

  example :marks, "Marks and tooltip",
    description:
      "marks are labelled stops under the track. An empty label renders a tick only, so you can mark every step and label the ones that carry meaning; ticks the fill has swallowed flip to the on-primary treatment. show_value=\"tooltip\" floats the value in a bubble over the thumb while you drag or tab to it, rather than taking up a row." do
    ~H"""
    <div class="w-full max-w-sm">
      <.slider
        name="year"
        label="Model year"
        value={2010}
        min={1990}
        max={2030}
        step={5}
        show_value="tooltip"
        marks={[
          %{value: 1990, label: "1990"},
          %{value: 2000, label: ""},
          %{value: 2010, label: "2010"},
          %{value: 2020, label: ""},
          %{value: 2030, label: "2030"}
        ]}
      />
    </div>
    """
  end

  example :sizes_states, "Sizes and states",
    description:
      "size runs sm, md, lg - track thickness and thumb diameter move together, so the proportions hold. disabled dims the whole control and takes the native inputs out of the tab order." do
    ~H"""
    <div class="w-full max-w-sm space-y-6">
      <.slider name="s" label="Small" value={30} size="sm" />
      <.slider name="m" label="Medium" value={50} size="md" />
      <.slider name="l" label="Large" value={70} size="lg" />
      <.slider name="d" label="Disabled" value={40} disabled />
    </div>
    """
  end

  example :vertical, "Vertical",
    description:
      "orientation=\"vertical\" stands the track up and fills from the bottom. It is the same native input turned with writing-mode, so the keyboard map and the screen reader announcement are unchanged - useful for a mixer strip or a level control that sits beside content rather than under it." do
    ~H"""
    <div class="flex items-end gap-10">
      <.slider name="bass" label="Bass" value={70} orientation="vertical" show_value="tooltip" />
      <.slider name="mid" label="Mid" value={45} orientation="vertical" show_value="tooltip" />
      <.slider
        name="treble"
        label="Treble"
        value={55}
        orientation="vertical"
        show_value="tooltip"
      />
    </div>
    """
  end
end
