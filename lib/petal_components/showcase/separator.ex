defmodule PetalComponents.Showcase.Separator do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Separator,
    title: "Separator"

  example :basic, "Plain rules",
    description:
      "A hairline with no margin of its own. The gap between these two rows comes from the layout, not the separator, which is the whole point: app chrome controls its own rhythm." do
    ~H"""
    <div class="max-w-md">
      <div class="text-sm font-medium text-gray-900 dark:text-white">Profile</div>
      <p class="text-sm text-gray-500 dark:text-gray-400">How other people see you.</p>
      <.separator class="my-4" />
      <div class="text-sm font-medium text-gray-900 dark:text-white">Notifications</div>
      <p class="text-sm text-gray-500 dark:text-gray-400">What lands in your inbox.</p>
    </div>
    """
  end

  example :or_divider, "The OR divider",
    description:
      "The one everybody builds twice a year: a labelled rule between a form and the OAuth buttons." do
    ~H"""
    <div class="max-w-xs">
      <.button label="Sign in with email" class="w-full" />
      <.separator label="OR" class="my-5" />
      <.button variant="outline" label="Continue with GitHub" class="w-full" />
    </div>
    """
  end

  example :label_positions, "Label position",
    description:
      "start, center and end. The short flank stays visible so the label still reads as part of the rule rather than a floating caption." do
    ~H"""
    <div class="max-w-md space-y-5">
      <.separator label="Yesterday" label_position="start" />
      <.separator label="Yesterday" label_position="center" />
      <.separator label="Yesterday" label_position="end" />
    </div>
    """
  end

  example :activity_feed, "A date separator in a feed",
    description:
      "Rich label content goes in the default slot, which wins over the label attr. Here it is an icon plus a date, centred the way feeds conventionally break days - start and end alignment are above, for labels that hug an edge." do
    ~H"""
    <div class="max-w-md">
      <div class="flex items-center gap-2 py-2 text-sm text-gray-700 dark:text-gray-300">
        <.avatar size="xs" name="Amelia Reid" random_color />Amelia closed PET-114
      </div>
      <.separator class="my-3">
        <span class="inline-flex items-center gap-1.5">
          <.icon name="hero-calendar-days" class="h-3.5 w-3.5" /> 12 August
        </span>
      </.separator>
      <div class="flex items-center gap-2 py-2 text-sm text-gray-700 dark:text-gray-300">
        <.avatar size="xs" name="Jonah Blake" random_color />Jonah shipped v4.14.0
      </div>
    </div>
    """
  end

  example :vertical, "Vertical",
    description:
      "A w-px rule that stretches to its flex parent. Give it a height when the parent does not, as in this toolbar - and pair the height with self-center, because an explicit height defeats the stretch and flexbox then parks the rule at the top of the row. Vertical separators are never labelled." do
    ~H"""
    <div class="inline-flex items-center gap-2 rounded-xl border border-gray-200 p-1.5 dark:border-gray-800">
      <.button variant="ghost" size="sm" label="Bold" />
      <.button variant="ghost" size="sm" label="Italic" />
      <.separator orientation="vertical" class="h-6 self-center" />
      <.button variant="ghost" size="sm" label="Link" />
      <.button variant="ghost" size="sm" label="Code" />
    </div>
    """
  end

  example :semantic, "Decorative or semantic",
    description:
      "Separators are decorative by default: aria-hidden, no role, no announcement. Pass decorative={false} when the rule really does divide content a screen reader should hear as separate, and it renders role=separator instead." do
    ~H"""
    <div class="max-w-md space-y-4">
      <.separator />
      <.separator decorative={false} />
    </div>
    """
  end
end
