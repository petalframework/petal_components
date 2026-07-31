defmodule PetalComponents.Showcase.Marquee do
  @moduledoc false
  use PetalComponents.Showcase, component: PetalComponents.Marquee, title: "Marquee"

  example :logos, "The logo strip",
    description:
      "The trusted-by row: an infinite scroller with edge fade, pausing under the pointer with pause_on_hover. Wordmarks here are plain styled text - swap in your logos as <img> tags and nothing else changes. repeat controls how many copies keep the loop seamless; duration and gap tune the feel. Holds still under prefers-reduced-motion." do
    ~H"""
    <.marquee pause_on_hover duration="30s" gap="4rem">
      <span
        :for={
          {name, style} <- [
            {"ACME", "font-black tracking-tighter"},
            {"Globex", "font-serif italic font-bold"},
            {"INITECH", "font-mono font-semibold tracking-widest"},
            {"Umbra", "font-extrabold tracking-tight"},
            {"Vandelay", "font-serif font-medium tracking-wide"},
            {"hooli", "font-black tracking-wide"}
          ]
        }
        class={["text-3xl text-gray-400 dark:text-gray-500", style]}
      >
        {name}
      </span>
    </.marquee>
    """
  end

  example :testimonials, "The testimonial wall",
    description:
      "Two counter-rotating rows of review cards - the social-proof wall from two marquees and one card component. No photo assets: review_card without img hashes a deterministic gradient monogram from each name. reverse sends the second row the other way; hover either row and it pauses for reading." do
    ~H"""
    <div class="flex w-full flex-col gap-4">
      <.marquee pause_on_hover duration="45s">
        <.review_card
          :for={
            {name, username, body} <- [
              {"Amelia Ward", "@ameliabuilds",
               "Shipped our whole settings area in an afternoon. The form components alone paid for the switch."},
              {"Jonah Reyes", "@jonahdev",
               "The dark mode just works. Every component, first try, no audit pass needed."},
              {"Priya Anand", "@priya_a",
               "Our AI assistant generates petal code that compiles. That was the moment for me."}
            ]
          }
          name={name}
          username={username}
          body={body}
          class="w-80 mx-2"
        />
      </.marquee>
      <.marquee pause_on_hover reverse duration="45s">
        <.review_card
          :for={
            {name, username, body} <- [
              {"Maya Okafor", "@mayacodes",
               "Radius token, colour dials, done. The whole app restyled without touching a component."},
              {"Tom Hale", "@tomhale",
               "Went from Figma to a working LiveView in a day. The stepper and slide-over are exactly right."},
              {"Ana Silva", "@anasilva",
               "put_flash renders as toasts now. Deleted a hundred lines of notification code."}
            ]
          }
          name={name}
          username={username}
          body={body}
          class="w-80 mx-2"
        />
      </.marquee>
    </div>
    """
  end
end
