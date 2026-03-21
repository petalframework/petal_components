defmodule PetalComponents.TestConstants do
  @moduledoc """
  Shared constants for testing Petal Components.
  """

  @colors ~w(primary secondary info success warning danger gray)
  @variants ~w(light dark soft outline shadow)
  @sizes ~w(xs sm md lg xl)

  def colors, do: @colors
  def variants, do: @variants
  def sizes, do: @sizes

  def button_class(color, variant \\ nil) do
    if variant, do: "pc-button--#{color}-#{variant}", else: "pc-button--#{color}"
  end

  def badge_class(color, variant), do: "pc-badge--#{color}-#{variant}"

  def alert_class(color), do: "pc-alert--#{color}"

  def alert_dismiss_button_class(color, variant \\ nil) do
    if variant,
      do: "pc-alert__dismiss-button--#{color}-#{variant}",
      else: "pc-alert__dismiss-button--#{color}"
  end

  def icon_button_bg_class(color), do: "pc-icon-button-bg--#{color}"
end
