defmodule PetalComponents.QrCodeTest do
  use ComponentCase
  import PetalComponents.QrCode

  # The `d` string of the single module path, for a square-module render.
  defp module_path(html) do
    html
    |> parse_html()
    |> LazyHTML.query("svg.pc-qr-code > path")
    |> LazyHTML.attribute("d")
    |> List.first()
  end

  describe "structure and accessibility" do
    test "renders an inline svg with the component class, role and default label" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" class="size-40 text-gray-900" />
        """)

      assert html =~ "<svg"
      assert_has_class(html, "pc-qr-code")
      assert_has_class(html, "size-40")
      assert_attribute(html, "role", "img")
      assert_attribute(html, "aria-label", "QR code")
    end

    test "the label is overridable and the encoded value never leaks into it" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code
          value="otpauth://totp/Petal:user@example.com?secret=JBSWY3DPEHPK3PXP"
          label="QR code to enrol your authenticator"
        />
        """)

      assert_attribute(html, "aria-label", "QR code to enrol your authenticator")
      refute html =~ "JBSWY3DPEHPK3PXP"
      refute html =~ "otpauth"
    end

    test "aria-label passed through rest wins over the label attr" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" aria-label="Scan me" />
        """)

      assert_attribute(html, "aria-label", "Scan me")
      refute html =~ ~s(aria-label="QR code")
    end

    test "aria-hidden drops the role and the label so screen readers skip it" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" aria-hidden="true" />
        """)

      assert_attribute(html, "aria-hidden", "true")
      refute_attribute(html, "role")
      refute html =~ "aria-label"
    end

    test "aria-hidden={false} means visible: role and label stay" do
      # presence is not truth - a dynamic aria-hidden={@x} that resolves
      # false must not silently strip the accessibility contract
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" aria-hidden={false} />
        """)

      assert_attribute(html, "role", "img")
      assert html =~ "aria-label"
    end

    test "hidden strips even a user-supplied aria-label from the globals" do
      # keeps the moduledoc's "neither is emitted" claim true rather than
      # depending on the caller not to contradict themselves
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" aria-hidden="true" aria-label="Pay here" />
        """)

      refute html =~ "aria-label"
      refute html =~ "Pay here"
    end

    test "class and rest pass through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" class="custom-qr" id="checkout-qr" data-role="share" />
        """)

      assert_has_class(html, "custom-qr")
      assert_attribute(html, "id", "checkout-qr")
      assert_attribute(html, "data-role", "share")
    end

    test "every dark module lands in one path, not one element per module" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" />
        """)

      paths = html |> parse_html() |> LazyHTML.query("path")
      assert Enum.count(paths) == 1
      refute html =~ "<rect"
    end
  end

  describe "encoding" do
    # A version-1 code is 21 modules wide; with the spec's 4-module quiet zone
    # on each side the viewBox is 29 units. "HELLO" fits in version 1 at :m.
    test "viewBox is the module grid plus a 4-module quiet zone on every side" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="HELLO" error_correction={:m} />
        """)

      assert html =~ ~s(viewBox="0 0 29 29")
    end

    test "a longer value picks a bigger version" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build/components/qr-code?utm_source=readme" />
        """)

      # version 4 -> 33 modules -> 41 with the quiet zone
      assert html =~ ~s(viewBox="0 0 41 41")
    end

    test "the finder patterns land where the spec says they do" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="HELLO" error_correction={:m} />
        """)

      d = module_path(html)

      # Three 7x7 finder patterns, each a solid top row. Offsets are quiet
      # zone (4) plus the module coordinate. A version-1 grid is 21 wide, so
      # the top-right finder starts at module 14 -> x 18.
      assert d =~ "M4 4h7v1h-7z", "expected the top-left finder pattern"
      assert d =~ "M18 4h7v1h-7z", "expected the top-right finder pattern"
      assert d =~ "M4 18h7v1h-7z", "expected the bottom-left finder pattern"

      # There is deliberately no finder in the bottom-right corner.
      refute d =~ "M18 18h7v1h-7z"

      # Row 1 of a finder is its two vertical edges, one module each.
      assert d =~ "M4 5h1v1h-1z"
      assert d =~ "M10 5h1v1h-1z"

      # The dark module: always set, at (8, 4 * version + 9) = (8, 13), which
      # with the quiet zone is (12, 17). It merges into the run starting there.
      assert d =~ "M12 17h"
    end

    # This matrix was verified out of band by rasterising the emitted path and
    # decoding it back to "HELLO" with OpenCV's QR detector, so the hash pins a
    # code that is known to scan, not just one that is self-consistent.
    test "known vector: the HELLO matrix at :m is pinned by hash" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="HELLO" error_correction={:m} />
        """)

      hash = :crypto.hash(:sha256, module_path(html)) |> Base.encode16(case: :lower)

      assert hash == "7c83f9bbdbbe37144f6fc2f4e583f604635f23215f86f4474229f24cd70c42e3",
             """
             The encoded QR matrix changed. That is fine if it was deliberate \
             (an encoder upgrade), but it means every previously rendered code \
             differs. Re-scan before updating this hash. Got: #{hash}
             """
    end

    test "each error correction level produces a different matrix" do
      assigns = %{}

      paths =
        for level <- [:l, :m, :q, :h] do
          assigns = %{level: level}

          rendered_to_string(~H"""
          <.qr_code value="https://petal.build" error_correction={@level} />
          """)
          |> module_path()
        end

      assert Enum.uniq(paths) == paths
    end

    test "a value past the capacity of the level raises with a useful message" do
      assigns = %{}

      error =
        assert_raise ArgumentError, fn ->
          rendered_to_string(~H"""
          <.qr_code value={String.duplicate("a", 1500)} error_correction={:h} />
          """)
        end

      assert Exception.message(error) =~ "1500 bytes"
      assert Exception.message(error) =~ "1273-byte ceiling"
      assert Exception.message(error) =~ ":l holds 2953 bytes"
    end

    test "a value that fits the ceiling of the level still renders" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value={String.duplicate("a", 1273)} error_correction={:h} />
        """)

      # version 40 -> 177 modules -> 185 with the quiet zone
      assert html =~ ~s(viewBox="0 0 185 185")
    end
  end

  describe "colour and background" do
    test "defaults are currentColor modules on no background at all" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" />
        """)

      assert_attribute(html, "fill", "currentColor")
      refute html =~ "<rect"
    end

    test "an explicit background paints a rect behind the whole code" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="HELLO" background="white" color="#111827" />
        """)

      rect = html |> parse_html() |> LazyHTML.query("rect")
      assert LazyHTML.attribute(rect, "fill") == ["white"]
      # The background covers the quiet zone too, or the code loses its margin.
      assert LazyHTML.attribute(rect, "width") == ["29"]
      assert_attribute(html, "fill", "#111827")
    end
  end

  describe "sizing" do
    test "size sets explicit width and height attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" size={200} />
        """)

      assert_attribute(html, "width", "200")
      assert_attribute(html, "height", "200")
    end

    test "without size the svg carries no dimensions and classes drive it" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" class="size-48" />
        """)

      refute_attribute(html, "width")
      refute_attribute(html, "height")
      assert_has_class(html, "size-48")
    end
  end

  describe "rounded modules" do
    test "square modules emit no arcs and ask for crisp edges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" />
        """)

      assert_attribute(html, "shape-rendering", "crispEdges")
      refute module_path(html) =~ "a"
    end

    test "rounded modules emit arcs and drop crisp edges" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" rounded={1} />
        """)

      refute_attribute(html, "shape-rendering")
      d = module_path(html)
      assert d =~ "a0.5 0.5 0 0 1"
      # At rounded=1 the straight run between arcs vanishes: full dots.
      assert d =~ "h0a0.5"
    end

    test "mid rounding uses a corner radius between square and full dots" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" rounded={0.5} />
        """)

      assert module_path(html) =~ "a0.25 0.25 0 0 1"
    end

    test "rounded clamps outside 0..1 instead of drawing nonsense" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" rounded={4} />
        """)

      assert module_path(html) =~ "a0.5 0.5 0 0 1"
      refute module_path(html) =~ "a2"
    end
  end

  describe "logo slot" do
    test "renders the slot content over a knocked-out centre" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" background="white">
          <:logo><span class="brand-mark">PC</span></:logo>
        </.qr_code>
        """)

      assert html =~ "brand-mark"
      assert html =~ "foreignObject"
      assert_has_class(html, "pc-qr-code__logo")

      # A nested svg gives the slot a 100x100 box scaled into the hole.
      inner = html |> parse_html() |> LazyHTML.query("svg svg")
      assert LazyHTML.attribute(inner, "viewBox") == ["0 0 100 100"]
    end

    test "the knockout actually removes modules from the path" do
      assigns = %{}

      without =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" error_correction={:h} />
        """)

      with_logo =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" error_correction={:h}>
          <:logo>logo</:logo>
        </.qr_code>
        """)

      assert String.length(module_path(with_logo)) < String.length(module_path(without))
    end

    test "the logo slot forces error correction to :h" do
      assigns = %{}

      # This value needs version 2 at :l (33 with the quiet zone) but version 3
      # at :h (37). Asking for :l with a logo must give you the :h geometry.
      at_l =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" error_correction={:l} />
        """)

      at_l_with_logo =
        rendered_to_string(~H"""
        <.qr_code value="https://petal.build" error_correction={:l}>
          <:logo>logo</:logo>
        </.qr_code>
        """)

      assert at_l =~ ~s(viewBox="0 0 33 33")
      assert at_l_with_logo =~ ~s(viewBox="0 0 37 37")
    end
  end

  describe "the optional encoder dependency" do
    test "the encoder is available in this environment" do
      # The guard raises with install instructions when eqrcode is missing.
      # It is present here (mix.exs declares it optional, so it is installed
      # for petal_components itself), which is what lets every test above run.
      assert Code.ensure_loaded?(EQRCode)
    end

    test "a missing encoder raises with the exact install instructions" do
      # the raise path is what a user without the optional dep actually hits;
      # the seam takes the encoder module so this is exercisable
      err =
        assert_raise RuntimeError, fn ->
          PetalComponents.QrCode.ensure_encoder!(PetalComponents.NoSuchEncoder)
        end

      assert err.message =~ ~s|{:eqrcode, "~> 0.2"}|
      assert err.message =~ "mix deps.get"
    end
  end
end
