defmodule PetalComponents.Showcase.Avatar do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Avatar, title: "Avatar"

  example :identity_without_photos, "Identity without photos",
    description:
      "The placeholder system, from plain to generative: monogram initials, a deterministic colour or gradient hashed from the name, and art - mesh draws a soft gradient orb (initials optional), dither a two-tone pixel blend. Same name, same result, every render. No JavaScript, no dependencies." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-4">
      <.avatar name="Sarah Chen" size="lg" />
      <.avatar name="Sarah Chen" size="lg" random_color />
      <.avatar name="Sarah Chen" size="lg" random_gradient />
      <.avatar name="Sarah Chen" size="lg" art="mesh" />
      <.avatar name="Sarah Chen" size="lg" art="mesh" initials />
      <.avatar name="Sarah Chen" size="lg" art="dither" />
    </div>
    """
  end

  example :rounded_shape, "Rounded for orgs",
    description:
      "Circles are the convention for people; shape=\"rounded\" gives orgs, teams and workspaces proportional soft corners instead. Deliberately independent of the radius dial - avatars are identity, not surface." do
    ~H"""
    <div class="flex flex-wrap items-center justify-center gap-4">
      <.avatar name="Petal Framework" size="lg" shape="rounded" random_gradient />
      <.avatar name="Acme Corp" size="lg" shape="rounded" art="mesh" />
      <.avatar name="Initech" size="lg" shape="rounded" art="dither" />
      <.avatar name="Globex" size="lg" shape="rounded" random_color />
    </div>
    """
  end

  example :sizes_and_presence, "Six sizes, four presence states",
    description:
      "The size ladder from 2xs to xl - 2xs is for dense rows: a table cell, a compact activity feed - and the status dot: online, busy, away, offline, ringed so it reads against any image or placeholder. Presence works on every avatar form." do
    ~H"""
    <div class="flex flex-col items-center gap-6">
      <div class="flex flex-wrap items-end justify-center gap-3">
        <.avatar name="Sarah Chen" size="2xs" random_color />
        <.avatar name="Sarah Chen" size="xs" random_color />
        <.avatar name="Sarah Chen" size="sm" random_color />
        <.avatar name="Sarah Chen" size="md" random_color />
        <.avatar name="Sarah Chen" size="lg" random_color />
        <.avatar name="Sarah Chen" size="xl" random_color />
      </div>
      <div class="flex flex-wrap items-center justify-center gap-4">
        <.avatar name="Amelia Ward" size="md" art="mesh" status="online" />
        <.avatar name="Jonah Reyes" size="md" art="mesh" status="busy" />
        <.avatar name="Priya Anand" size="md" art="mesh" status="away" />
        <.avatar name="Tom Hale" size="md" art="mesh" status="offline" />
      </div>
    </div>
    """
  end

  example :group_stack, "The team stack",
    description:
      "avatar_group overlaps your hosted image URLs into the classic team pile; max caps the row and folds the rest into a +N bubble. shape passes through to every avatar and the bubble. The URLs here are inline SVG stand-ins - swap in real photos and nothing else changes." do
    ~H"""
    <div class="flex flex-col items-center gap-4">
      <.avatar_group
        size="md"
        max={3}
        avatars={[
          "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 8 8'><rect width='8' height='8' fill='%23f59e0b'/></svg>",
          "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 8 8'><rect width='8' height='8' fill='%2310b981'/></svg>",
          "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 8 8'><rect width='8' height='8' fill='%236366f1'/></svg>",
          "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 8 8'><rect width='8' height='8' fill='%23ec4899'/></svg>",
          "data:image/svg+xml;utf8,<svg xmlns='http://www.w3.org/2000/svg' viewBox='0 0 8 8'><rect width='8' height='8' fill='%2306b6d4'/></svg>"
        ]}
      />
    </div>
    """
  end
end
