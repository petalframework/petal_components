defmodule PetalComponents.LocalTimeTest do
  use ComponentCase
  import PetalComponents.LocalTime

  describe "local_time/1" do
    test "renders a hook-bound time element with the UTC ISO as datetime and fallback" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.local_time id="t" at={~U[2026-07-21 08:30:00Z]} />
        """)

      assert html =~ "<time"
      assert html =~ ~s(phx-hook="PetalLocalTime")
      assert html =~ ~s(datetime="2026-07-21T08:30:00Z")
      # SSR fallback content is the ISO itself
      assert html =~ ">2026-07-21T08:30:00Z</time>"
      assert html =~ ~s(data-format="datetime")
    end

    test "normalises an offset DateTime to UTC without a timezone database" do
      {:ok, dt, _offset} = DateTime.from_iso8601("2026-07-21T18:30:00+10:00")
      assigns = %{dt: dt}

      html =
        rendered_to_string(~H"""
        <.local_time id="t" at={@dt} />
        """)

      assert html =~ ~s(datetime="2026-07-21T08:30:00Z")
    end

    test "assumes UTC for a NaiveDateTime" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.local_time id="t" at={~N[2026-07-21 08:30:00]} />
        """)

      assert html =~ ~s(datetime="2026-07-21T08:30:00Z")
    end

    test "relative format carries threshold and title flags" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.local_time id="t" at={~U[2026-07-21 08:30:00Z]} format="relative" />
        """)

      assert html =~ ~s(data-format="relative")
      assert html =~ ~s(data-threshold="604800")
      assert html =~ ~s(data-title="true")
    end

    test "title can be disabled and threshold overridden" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.local_time
          id="t"
          at={~U[2026-07-21 08:30:00Z]}
          format="relative"
          threshold={3600}
          title={false}
        />
        """)

      assert html =~ ~s(data-threshold="3600")
      assert html =~ ~s(data-title="false")
    end

    test "a map format passes Intl options through as JSON" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.local_time id="t" at={~U[2026-07-21 08:30:00Z]} format={%{dateStyle: "full"}} />
        """)

      assert html =~ ~s(data-format="custom")
      assert html =~ "dateStyle"
      assert html =~ "full"
    end

    test "locale and timezone overrides render as data attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.local_time id="t" at={~U[2026-07-21 08:30:00Z]} locale="de-DE" timezone="Europe/Berlin" />
        """)

      assert html =~ ~s(data-locale="de-DE")
      assert html =~ ~s(data-timezone="Europe/Berlin")
    end
  end
end
