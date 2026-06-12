defmodule PetalComponents.ConfettiTest do
  use ComponentCase
  import PetalComponents.Confetti

  describe "basic rendering" do
    test "renders an invisible mount point with the hook" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.confetti id="confetti" />
        """)

      assert html =~ "pc-confetti"
      assert html =~ ~s(phx-hook="PetalConfetti")
      assert html =~ ~s(id="confetti")
      assert html =~ ~s(data-particle-count="100")
      assert html =~ ~s(data-spread="70")
      refute html =~ "data-colors"
    end
  end

  describe "customization" do
    test "applies custom particle count, spread and colors" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.confetti id="confetti" particle_count={150} spread={90} colors={["#ff0000", "#00ff00"]} />
        """)

      assert html =~ ~s(data-particle-count="150")
      assert html =~ ~s(data-spread="90")
      assert html =~ "data-colors="
      assert html =~ "#ff0000"
    end
  end
end
