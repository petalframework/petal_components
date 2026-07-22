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
end
