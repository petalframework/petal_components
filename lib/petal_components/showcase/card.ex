defmodule PetalComponents.Showcase.Card do
  @moduledoc false
  use PetalComponents.Showcase,
    component: PetalComponents.Card,
    title: "Card",
    functions: [:card, :card_header, :card_content, :card_footer, :card_media, :review_card]

  example :login, "Composed from parts",
    description:
      "The container for everything, assembled from parts: card_header carries title, description and a top-right :action; card_content and card_footer pad themselves so media can run full-bleed when you add it. The login card is the canonical composition." do
    ~H"""
    <.card class="w-full max-w-sm">
      <.card_header title="Login to your account" description="Enter your email below to login">
        <:action>
          <.button color="gray" variant="ghost" size="sm" link_type="a" to="#">
            Sign up
          </.button>
        </:action>
      </.card_header>
      <.card_content>
        <div class="flex flex-col gap-4">
          <.field type="email" name="email" value="" label="Email" placeholder="m@example.com" />
          <.field type="password" name="password" value="" label="Password" />
        </div>
      </.card_content>
      <.card_footer class="flex-col">
        <.button class="w-full">Login</.button>
        <.social_button provider="google" label="Login with Google" class="w-full" />
      </.card_footer>
    </.card>
    """
  end

  example :variants, "The panel and the well",
    description:
      "Two variants, two jobs: basic is the bordered panel that asserts - the only card most screens need - and muted is the quiet tinted well for secondary content, form sections and stat tiles. (variant=\"outline\" still renders as a legacy alias of basic, going away in 5.0.)" do
    ~H"""
    <div class="grid w-full max-w-2xl gap-6 md:grid-cols-2">
      <.card>
        <.card_header title="Basic" description="The card" />
        <.card_content>
          The bordered panel - primary content lives here. This is the default and
          the only card most screens need.
        </.card_content>
      </.card>
      <.card variant="muted">
        <.card_header title="Muted" description="The well" />
        <.card_content>
          A quiet tinted fill, no border - secondary content, form sections, stat
          tiles. It recedes where basic asserts.
        </.card_content>
      </.card>
    </div>
    """
  end
end
