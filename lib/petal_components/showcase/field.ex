defmodule PetalComponents.Showcase.Field do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Field, title: "Form field"

  # One module covers the whole form-field surface (text inputs, select,
  # checkbox, radio, switch) because they are all one component function -
  # <.field type=...> - and the registry maps one module per component.
  # The playground splits these examples across its input / select / checkbox /
  # radio / switch pages by id; marketing can render the full spread in order.

  example :anatomy, "Anatomy",
    description:
      "label, control and help_text on one surface - the label rhythm and muted help tier come free. name and label are all a working field needs; type swaps the control without changing the wrapper." do
    ~H"""
    <div class="w-full max-w-sm">
      <.field
        type="email"
        name="anatomy_email"
        label="Email address"
        value=""
        placeholder="you@example.com"
        help_text="We only use this for receipts."
        no_margin
      />
    </div>
    """
  end

  example :error_state, "Error state",
    description:
      "Pass errors as a list of messages and the field paints the border and message in the danger tone. With a changeset-backed field={f[:email]} the errors arrive automatically." do
    ~H"""
    <div class="w-full max-w-sm">
      <.field
        type="email"
        name="error_email"
        label="Email address"
        value="not-an-email"
        errors={["must include an @ sign"]}
        no_margin
      />
    </div>
    """
  end

  example :in_field_actions, "In-field actions",
    description:
      "Buttons that live inside the control, no extra markup: viewable toggles password visibility, copyable puts the value on the clipboard, clearable empties the input. All petal-bundled JS." do
    ~H"""
    <div class="w-full max-w-sm space-y-6">
      <.field
        type="password"
        name="pw_viewable"
        label="Password (viewable)"
        value="hunter2hunter2"
        viewable
        no_margin
      />
      <.field
        type="text"
        name="api_key"
        label="API key (copyable)"
        value="pk_live_51J8s0"
        copyable
        no_margin
      />
      <.field
        type="search"
        name="search_q"
        label="Search (clearable)"
        value="petal components"
        clearable
        no_margin
      />
    </div>
    """
  end

  example :every_type, "Every native type",
    description:
      "The native types on one surface. The date family gets a button that opens the native picker; type=\"hidden\" renders nothing visible - form plumbing only. For range and range-dual, see slider." do
    ~H"""
    <div class="grid w-full gap-x-8 gap-y-6 sm:grid-cols-2">
      <.field type="tel" name="et_tel" label="Phone" value="" placeholder="0400 000 000" no_margin />
      <.field
        type="url"
        name="et_url"
        label="Website"
        value=""
        placeholder="https://petal.build"
        no_margin
      />
      <.field type="date" name="et_date" label="Date" value="2026-07-22" no_margin />
      <.field type="time" name="et_time" label="Time" value="09:30" no_margin />
      <.field
        type="datetime-local"
        name="et_dtl"
        label="Date and time"
        value="2026-07-22T09:30"
        no_margin
      />
      <.field type="month" name="et_month" label="Month" value="2026-07" no_margin />
      <.field type="week" name="et_week" label="Week" value="2026-W30" no_margin />
      <.field type="color" name="et_color" label="Brand color" value="#7c3aed" no_margin />
      <.field type="file" name="et_file" label="Attachment" no_margin />
    </div>
    """
  end

  example :select, "Select",
    description:
      "type=\"select\" wraps the native select on the shared field surface: prompt renders the placeholder option and options takes the same shapes as Phoenix's options_for_select/2. No JS, native keyboard and mobile behaviour." do
    ~H"""
    <div class="w-full max-w-sm">
      <.field
        type="select"
        name="country"
        label="Country"
        value=""
        prompt="Pick a country"
        options={["Australia", "New Zealand", "Japan"]}
        help_text="Where you pay tax."
        no_margin
      />
    </div>
    """
  end

  example :select_groups, "Option groups",
    description:
      "A keyword list of lists renders native optgroups - the same shape options_for_select/2 takes everywhere else." do
    ~H"""
    <div class="w-full max-w-sm">
      <.field
        type="select"
        name="region"
        label="Region"
        value="Sydney"
        options={[
          APAC: ["Sydney", "Tokyo", "Singapore"],
          Europe: ["Amsterdam", "Berlin"],
          Americas: ["Denver", "Sao Paulo"]
        ]}
        no_margin
      />
    </div>
    """
  end

  example :select_multiple, "Multiple select",
    description:
      "multiple grows the control and posts a list - name the field with [] so every choice survives the form post. value pre-selects." do
    ~H"""
    <div class="w-full max-w-sm">
      <.field
        type="select"
        name="channels[]"
        label="Notification channels"
        value={["Email", "Slack"]}
        options={["Email", "Slack", "SMS", "Webhook"]}
        multiple
        help_text="Cmd-click to select more than one."
        no_margin
      />
    </div>
    """
  end

  example :checkbox_group, "Checkbox group",
    description:
      "type=\"checkbox-group\" is the multi-select: {label, value} options, value pre-checks, group_layout flows row or stacks col. The component names the boxes with [] itself and keeps a hidden empty input, so the param posts a list even when nothing is ticked." do
    ~H"""
    <div class="w-full max-w-sm">
      <.field
        type="checkbox-group"
        name="stack"
        label="Stack"
        value={["phoenix"]}
        options={[{"Phoenix", "phoenix"}, {"LiveView", "live_view"}, {"Oban", "oban"}]}
        no_margin
      />
    </div>
    """
  end

  example :checkbox_states, "Checkbox states",
    description:
      "The four states. The box nests the theme radius a step in, and the focus ring only shows for keyboard focus - clicking stays quiet." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-x-8 gap-y-4">
      <.field type="checkbox" name="s_off" label="Unchecked" no_margin />
      <.field type="checkbox" name="s_on" label="Checked" checked no_margin />
      <.field type="checkbox" name="s_dis" label="Disabled" disabled no_margin />
      <.field type="checkbox" name="s_dis_on" label="Disabled checked" checked disabled no_margin />
    </div>
    """
  end

  example :checkbox_single, "Single checkbox",
    description:
      "The agreement pattern: one checkbox, the label carries the sentence, help_text the fine print." do
    ~H"""
    <div class="w-full max-w-sm">
      <.field
        type="checkbox"
        name="terms"
        label="I agree to the terms and privacy policy"
        help_text="You can withdraw consent at any time."
        no_margin
      />
    </div>
    """
  end

  example :radio_group, "Radio group",
    description:
      "type=\"radio-group\" for plain radios: {label, value} options, value selects one, group_layout=\"col\" stacks the row." do
    ~H"""
    <div class="w-full max-w-sm">
      <.field
        type="radio-group"
        name="billing"
        label="Billing period"
        value="monthly"
        options={[{"Monthly", "monthly"}, {"Yearly (save 20%)", "yearly"}]}
        no_margin
      />
    </div>
    """
  end

  example :radio_cards, "Radio cards",
    description:
      "type=\"radio-card\" turns options into selectable panels - label, description and an icon or image per option map, the pattern most libraries make you hand-roll. group_layout=\"col\" stacks them; indicator adds the dot and indicator_position=\"corner\" tucks it out of the text column." do
    ~H"""
    <div class="w-full max-w-sm">
      <.field
        type="radio-card"
        name="pay_method"
        label="Payment method"
        value="visa"
        group_layout="col"
        indicator
        indicator_position="corner"
        options={[
          %{
            value: "visa",
            label: "Visa ending in 4242",
            description: "Expires 12/26",
            icon: "hero-credit-card"
          },
          %{
            value: "mastercard",
            label: "Mastercard ending in 8888",
            description: "Expires 09/25",
            icon: "hero-credit-card"
          },
          %{value: "new", label: "Add new payment method", icon: "hero-plus"}
        ]}
        no_margin
      />
    </div>
    """
  end

  example :radio_card_tiles, "Icon tiles",
    description:
      "Radio cards take any layout: pass class to arrange the group yourself - here a two-column grid of icon tiles." do
    ~H"""
    <div class="w-full max-w-md">
      <.field
        type="radio-card"
        name="modules"
        label="Enable a module"
        value="payments"
        class="grid grid-cols-2 gap-3"
        indicator
        indicator_position="corner"
        options={[
          %{
            value: "payments",
            label: "Payments",
            description: "Receive payments from your customers",
            icon: "hero-banknotes"
          },
          %{
            value: "invoices",
            label: "Invoices",
            description: "Create and send invoices to your customers",
            icon: "hero-document-text"
          },
          %{
            value: "billing",
            label: "Billing",
            description: "Manage your billing and subscriptions",
            icon: "hero-credit-card"
          },
          %{
            value: "reports",
            label: "Reports",
            description: "View your reports and analytics",
            icon: "hero-chart-bar"
          }
        ]}
        no_margin
      />
    </div>
    """
  end

  example :radio_card_disabled, "Disabled option",
    description:
      "Disable one option with disabled: true in its map - it fades and refuses the pointer while the rest stay live. disabled on the field itself greys the whole group." do
    ~H"""
    <div class="w-full max-w-lg">
      <.field
        type="radio-card"
        name="tier"
        label="Tier"
        value="cloud"
        options={[
          %{value: "cloud", label: "Cloud", description: "Managed for you"},
          %{value: "self", label: "Self-hosted", description: "Coming soon", disabled: true}
        ]}
        no_margin
      />
    </div>
    """
  end

  example :sliders, "Sliders",
    description:
      "type=\"range\" is the native input on the shared field surface - no JavaScript when plain. fill paints the track primary up to the thumb (Firefox natively, a tiny hook for webkit); leave it off for balance and pan controls, where a fill would imply a wrong zero point. step snaps the scale." do
    ~H"""
    <div class="grid w-full gap-x-10 gap-y-6 sm:grid-cols-2">
      <.field type="range" name="volume" label="Volume" value="60" min="0" max="100" fill no_margin />
      <.field
        type="range"
        name="stepped"
        label="Stepped (10s)"
        value="40"
        min="0"
        max="100"
        step="10"
        fill
        no_margin
      />
      <.field type="range" name="balance" label="Balance" value="50" min="0" max="100" no_margin />
      <.field type="range" name="range_dis" label="Disabled" value="30" disabled no_margin />
    </div>
    """
  end

  example :slider_dual, "Dual range",
    description:
      "type=\"range-dual\" is two thumbs and a hook for min/max filtering - same track, thumb and focus ring as the single. min_field and max_field take form fields (in your app, @form[:min] and @form[:max]); value_prefix formats the readout and range_max_label caps the scale as open-ended." do
    ~H"""
    <div class="w-full max-w-sm">
      <.field
        type="range-dual"
        min_field={to_form(%{"min" => "100"}, as: :price)[:min]}
        max_field={to_form(%{"max" => "600"}, as: :price)[:max]}
        range_min={0}
        range_max={1000}
        step={50}
        value_prefix="$"
        range_max_label="$1,000+"
        label="Price"
        no_margin
      />
    </div>
    """
  end

  example :switch, "Switch",
    description:
      "type=\"switch\" is the checkbox for instant effect - on or off, applied immediately, no save button implied. checked starts it on; disabled freezes either position." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-x-10 gap-y-4">
      <.field type="switch" name="st_off" label="Off" no_margin />
      <.field type="switch" name="st_on" label="On" checked no_margin />
      <.field type="switch" name="st_dis" label="Disabled" disabled no_margin />
      <.field type="switch" name="st_dis_on" label="Disabled on" checked disabled no_margin />
    </div>
    """
  end

  example :switch_sizes, "Switch sizes",
    description:
      "size runs xs to xl on the shared form scale, md the default. Switches stay pill-shaped whatever the radius theme says - they are a shape, not a surface." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-x-10 gap-y-4">
      <.field
        :for={z <- ~w(xs sm md lg xl)}
        type="switch"
        name={"sz_" <> z}
        label={z}
        size={z}
        checked
        no_margin
      />
    </div>
    """
  end
end
