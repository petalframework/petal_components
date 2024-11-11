defmodule PetalComponents.MarqueeTest do
  use ComponentCase
  import PetalComponents.Marquee

  describe "basic rendering" do
    test "renders with proper base classes" do
      assigns = %{
        items: ["Item 1", "Item 2", "Item 3"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee>
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      assert html =~ "pc-marquee-container"
      assert html =~ "pc-marquee-content"
      assert html =~ "pc-marquee-horizontal"
    end

    test "renders correct number of repeats" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee repeat={3}>
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      content_divs = html |> String.split("pc-marquee-content") |> length() |> Kernel.-(1)
      assert content_divs == 3
    end

    test "doesn't render when repeat is 0" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee repeat={0}>
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      refute html =~ "pc-marquee-content"
    end
  end

  describe "orientation variants" do
    test "applies vertical classes correctly" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee vertical>
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      assert html =~ "pc-vertical"
      assert html =~ "pc-marquee-vertical"
      refute html =~ "pc-marquee-horizontal"
    end
  end

  describe "animation controls" do
    test "applies pause on hover class" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee pause_on_hover>
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      assert html =~ "pc-pause-on-hover"
    end

    test "applies reverse animation style" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee reverse>
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      assert html =~ "animation-direction: reverse"
    end

    test "applies custom duration and gap" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee duration="50s" gap="2rem">
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      assert html =~ "--duration: 50s"
      assert html =~ "--gap: 2rem"
    end
  end

  describe "gradient overlay" do
    test "renders gradient overlays by default" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee>
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      assert html =~ "pc-gradient-overlay-left"
      assert html =~ "pc-gradient-overlay-right"
    end

    test "renders vertical gradient overlays when vertical" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee vertical>
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      assert html =~ "pc-gradient-overlay-top"
      assert html =~ "pc-gradient-overlay-bottom"
    end

    test "doesn't render gradient overlays when disabled" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee overlay_gradient={false}>
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      refute html =~ "pc-gradient-overlay"
    end
  end

  describe "size constraints" do
    test "applies max width classes" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee max_width="xl">
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      assert html =~ ~s(max-width="xl")
    end

    test "applies max height classes" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee max_height="lg">
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      assert html =~ ~s(max-height="lg")
    end
  end

  describe "customization" do
    test "applies custom classes" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee class="custom-class">
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      assert html =~ "custom-class"
    end

    test "passes through rest attributes" do
      assigns = %{
        items: ["Item 1"]
      }

      html =
        rendered_to_string(~H"""
        <.marquee data-test="marquee">
          <%= for item <- @items do %>
            <div><%= item %></div>
          <% end %>
        </.marquee>
        """)

      assert html =~ ~s(data-test="marquee")
    end
  end
end
