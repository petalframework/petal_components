defmodule PetalComponents.QrCode do
  @moduledoc """
  A QR code rendered as pure server-side SVG - zero JavaScript, crisp at any
  size, themeable with `currentColor`, and it prints.

      <.qr_code value="https://petal.build" class="size-40 text-gray-900 dark:text-white" />

  Every dark module lands in a single `<path>`, so a dense code is one DOM node
  rather than eight hundred. Size it with classes (`size-40`, `w-64 h-64`) or
  pass `size` for explicit pixel width/height attributes.

  ## The encoder is an optional dependency

  Encoding a QR code is real algorithmic work - byte-mode segmentation, Reed-
  Solomon error correction, mask evaluation - so the matrix comes from
  [`eqrcode`](https://hex.pm/packages/eqrcode) (MIT, pure Elixir, no
  dependencies of its own). It is declared `optional: true`, which means it is
  **not** installed into your app unless you ask for it:

      # mix.exs
      {:eqrcode, "~> 0.2"}

  Render `<.qr_code>` without it and you get a loud error with those
  instructions rather than a blank box. Everything downstream of the matrix -
  the SVG, the quiet zone, module rounding, the logo knockout, theming - is
  ours.

  ## Dark mode: the inversion rule

  QR scanners expect **dark modules on a light background**. Two ways to stay
  scannable on a dark surface, in order of safety:

    * **(a) The safe default - keep the code dark-on-light.** Give it an
      explicit light `background` and let it sit on a light card. Works with
      every scanner ever made, including the cheap ones and the ones printed
      on receipts.

          <div class="rounded-xl bg-white p-4">
            <.qr_code value={@url} background="white" class="size-40 text-gray-900" />
          </div>

    * **(b) Inverted - light modules on the dark surface.** Looks better on a
      dark panel and most modern phone cameras handle it, but some older and
      embedded scanners do not. If you take this route the quiet zone must be
      the dark surface colour too (leave `background` transparent so the
      surface shows through), and the contrast must be high - never grey on
      grey.

          <div class="bg-gray-900 p-6">
            <.qr_code value={@url} class="size-40 text-white" />
          </div>

  Because `color` defaults to `currentColor`, `class="text-gray-900
  dark:text-white"` gives you (b) automatically in dark mode. That is a
  deliberate choice - it is the good-looking default - but if your audience
  might be scanning with something old, pick (a) and test.

  ## Accessibility

  The `<svg>` is `role="img"` with a default `aria-label` of `"QR code"`.
  Override it with `label` (or your own `aria-label`) to say what the code
  actually points at - `"QR code linking to your account settings"`. The value
  is **never** used as the label: it is often a secret (a TOTP enrolment URI
  contains the shared secret) and reading a URL aloud character by character
  helps nobody.

  Pass `aria-hidden="true"` when the same information sits next to the code as
  real text - a QR code must never be the only route to the content. Doing so
  drops `role` and the label, so screen readers skip straight to the text.

  ## Logo slot

  The `:logo` slot knocks a hole in the middle of the code and renders your
  content there. Using it forces `error_correction` to `:h`, the level that
  tolerates ~30% loss, so the code still scans with the hole in it. Slot
  content is laid out in a 100x100 box that is scaled to fit the knockout, so
  size things in that coordinate space.

      <.qr_code value="https://petal.build" background="white" class="size-48">
        <:logo>
          <div style="display:flex;align-items:center;justify-content:center;height:100%">
            <img src="/images/logo.svg" width="70" height="70" />
          </div>
        </:logo>
      </.qr_code>
  """
  use Phoenix.Component

  # Byte-mode capacity of a version-40 code, per error correction level.
  @capacity %{l: 2953, m: 2331, q: 1663, h: 1273}

  # The spec's mandatory quiet zone, in modules, on every side.
  @quiet_zone 4

  # Fraction of the code's width the logo knockout is allowed to eat. EC :h
  # recovers ~30% of the code, so a quarter leaves headroom.
  @knockout_ratio 0.25

  attr :value, :string,
    required: true,
    doc: "the string to encode (URL, otpauth:// URI, WiFi string, arbitrary text)"

  attr :size, :any,
    default: nil,
    doc:
      ~s|optional pixel size, setting width/height attributes; omit it and drive the size with classes instead, e.g. class="size-48"|

  attr :color, :string,
    default: "currentColor",
    doc:
      "module (dark) colour; currentColor by default so it themes with text-* classes and prints"

  attr :background, :string,
    default: "transparent",
    doc:
      ~s|fill behind the modules, quiet zone included; transparent by default. Set it (e.g. "white") when placing the code on a dark or busy surface|

  attr :error_correction, :atom,
    default: :m,
    values: [:l, :m, :q, :h],
    doc: "error correction level, low to high; forced to :h when the logo slot is used"

  attr :rounded, :any,
    default: 0,
    doc: "0..1 module corner rounding: 0 = square modules, 1 = fully round dots"

  attr :label, :string,
    default: "QR code",
    doc: "accessible name for the code. Never derived from value, which is often a secret"

  attr :class, :any,
    default: nil,
    doc: ~s|size + colour, e.g. "size-48 text-gray-900 dark:text-white"|

  attr :rest, :global

  slot :logo,
    doc:
      "optional centre logo, rendered in a knocked-out hole in the middle of the code. Forces error_correction to :h. Content is laid out in a 100x100 box scaled to fit the hole"

  @doc """
  Renders a QR code as inline SVG.

  See `PetalComponents.QrCode` for the encoder dependency, the dark-mode
  inversion rule and accessibility guidance.
  """
  def qr_code(assigns) do
    level = if assigns.logo != [], do: :h, else: assigns.error_correction
    rounded = clamp(assigns.rounded)
    grid = encode!(assigns.value, level)
    n = length(grid)
    knockout = if assigns.logo != [], do: knockout_bounds(n), else: nil

    # aria-hidden={false} must read as NOT hidden (a dynamic aria-hidden={@x}
    # is normal HEEx), and when genuinely hidden, a user-supplied aria-label
    # in the globals is stripped so the "neither is emitted" contract in the
    # moduledoc stays true rather than depending on the caller.
    hidden? = hidden_attr?(assigns.rest)
    rest = if hidden?, do: drop_attr(assigns.rest, "aria-label"), else: assigns.rest

    assigns =
      assigns
      |> assign(:rest, rest)
      |> assign(:d, path(grid, rounded, knockout))
      |> assign(:extent, n + @quiet_zone * 2)
      |> assign(:crisp, if(rounded == 0.0, do: "crispEdges"))
      |> assign(:logo_box, logo_box(knockout))
      |> assign(:hidden?, hidden?)
      |> assign(:labelled?, not given?(rest, "aria-label"))
      |> assign(:paint_background?, assigns.background not in ["transparent", "none", nil])

    ~H"""
    <svg
      viewBox={"0 0 #{@extent} #{@extent}"}
      width={@size}
      height={@size}
      shape-rendering={@crisp}
      role={unless @hidden?, do: "img"}
      aria-label={if @labelled? and not @hidden?, do: @label}
      class={["pc-qr-code", @class]}
      {@rest}
    >
      <rect :if={@paint_background?} width={@extent} height={@extent} fill={@background} />
      <path d={@d} fill={@color} />
      <svg
        :if={@logo_box}
        x={elem(@logo_box, 0)}
        y={elem(@logo_box, 1)}
        width={elem(@logo_box, 2)}
        height={elem(@logo_box, 2)}
        viewBox="0 0 100 100"
      >
        <foreignObject width="100" height="100">
          <div xmlns="http://www.w3.org/1999/xhtml" class="pc-qr-code__logo">
            {render_slot(@logo)}
          </div>
        </foreignObject>
      </svg>
    </svg>
    """
  end

  # Global attributes arrive keyed by string or atom depending on how they were
  # written at the call site; treat both the same.
  defp given?(rest, key), do: Enum.any?(rest, fn {k, _} -> to_string(k) == key end)

  # Presence is not truth: aria-hidden={false} and aria-hidden="false" mean
  # visible, and HEEx renders a literal false attr value by omitting it.
  defp hidden_attr?(rest) do
    Enum.any?(rest, fn {k, v} ->
      to_string(k) == "aria-hidden" and v not in [false, "false", nil]
    end)
  end

  defp drop_attr(rest, key) do
    rest |> Enum.reject(fn {k, _} -> to_string(k) == key end) |> Map.new()
  end

  # -- encoding ---------------------------------------------------------------

  # The matrix comes from eqrcode; the rest of this module is ours. eqrcode
  # bakes in a 2-module border, which we strip so we can lay down the spec's
  # 4-module quiet zone ourselves.
  defp encode!(value, level) do
    ensure_encoder!(EQRCode)
    check_capacity!(value, level)

    encoded = EQRCode.encode(value, level)
    padded = tuple_size(encoded.matrix)
    # A version v code is 4v + 17 modules wide; the rest is eqrcode's padding.
    border = div(padded - (4 * encoded.version + 17), 2)

    for y <- border..(padded - border - 1) do
      row = elem(encoded.matrix, y)
      for x <- border..(padded - border - 1), do: elem(row, x)
    end
  end

  # Public with the module as an argument so the raise path (the install
  # instructions users actually hit) is testable; production always passes
  # EQRCode.
  @doc false
  def ensure_encoder!(encoder) do
    if not Code.ensure_loaded?(encoder) do
      raise """
      <.qr_code> needs the eqrcode package to build the QR matrix, and it is not available.

      Add it to your deps in mix.exs and run `mix deps.get`:

          {:eqrcode, "~> 0.2"}

      It is MIT-licensed, pure Elixir, and pulls in nothing else. petal_components
      declares it optional so apps that never render a QR code do not carry it.
      """
    end
  end

  defp check_capacity!(value, level) do
    max = @capacity[level]

    if byte_size(value) > max do
      raise ArgumentError, """
      qr_code value is #{byte_size(value)} bytes, past the #{max}-byte ceiling of a \
      QR code at error correction level #{inspect(level)}.

      Shorten the value (a redirect URL instead of the full one is the usual fix) or \
      drop the error correction level - :l holds #{@capacity.l} bytes. Note that the \
      logo slot forces the level to :h, the smallest at #{@capacity.h} bytes.\
      """
    end
  end

  # -- geometry ---------------------------------------------------------------

  defp clamp(rounded) when is_number(rounded), do: rounded |> max(0) |> min(1) |> Kernel.*(1.0)
  defp clamp(_), do: 0.0

  # The knockout is an odd number of modules so it centres on the middle
  # module of the (always odd) grid.
  defp knockout_bounds(n) do
    span = trunc(n * @knockout_ratio)
    span = if rem(span, 2) == 0, do: span - 1, else: span
    centre = div(n, 2)
    half = div(span, 2)
    {centre - half, centre + half}
  end

  defp logo_box(nil), do: nil

  defp logo_box({lo, hi}) do
    # Inset half a module so the surviving modules never touch the artwork.
    {fmt(@quiet_zone + lo + 0.5), fmt(@quiet_zone + lo + 0.5), fmt(hi - lo + 1 - 1.0)}
  end

  # One `d` string for every dark module. Square modules merge into horizontal
  # runs - fewer bytes, and no hairline seams between neighbours. Rounded
  # modules stay individual, which is the whole point of the look.
  defp path(grid, rounded, knockout) do
    grid
    |> Enum.with_index()
    |> Enum.map_join(fn {row, y} ->
      row
      |> Enum.with_index()
      |> Enum.reject(fn {module, x} -> module != 1 or knocked_out?(knockout, x, y) end)
      |> Enum.map(fn {_, x} -> x end)
      |> draw_row(y, rounded)
    end)
  end

  defp knocked_out?(nil, _x, _y), do: false
  defp knocked_out?({lo, hi}, x, y), do: x >= lo and x <= hi and y >= lo and y <= hi

  defp draw_row(xs, y, rounded) when rounded == 0.0 do
    xs
    |> runs()
    |> Enum.map_join(fn {x, width} ->
      "M#{x + @quiet_zone} #{y + @quiet_zone}h#{width}v1h-#{width}z"
    end)
  end

  defp draw_row(xs, y, rounded) do
    r = rounded / 2
    Enum.map_join(xs, &rounded_module(&1 + @quiet_zone, y + @quiet_zone, r))
  end

  # Consecutive x positions collapse to {start, width}.
  defp runs(xs) do
    xs
    |> Enum.reduce([], fn
      x, [{start, width} | rest] when x == start + width -> [{start, width + 1} | rest]
      x, acc -> [{x, 1} | acc]
    end)
    |> Enum.reverse()
  end

  defp rounded_module(x, y, r) do
    # Straight run between the corner arcs; zero at r = 0.5, where the module
    # becomes a circle.
    straight = fmt(1 - r * 2)
    arc = "a#{fmt(r)} #{fmt(r)} 0 0 1 "

    "M#{fmt(x + r)} #{y}" <>
      "h#{straight}#{arc}#{fmt(r)} #{fmt(r)}" <>
      "v#{straight}#{arc}-#{fmt(r)} #{fmt(r)}" <>
      "h-#{straight}#{arc}-#{fmt(r)} -#{fmt(r)}" <>
      "v-#{straight}#{arc}#{fmt(r)} -#{fmt(r)}z"
  end

  # Compact, stable float output: "0.5", not "0.500".
  defp fmt(f) do
    f = f * 1.0

    if f == Float.round(f) do
      f |> trunc() |> Integer.to_string()
    else
      f |> :erlang.float_to_binary(decimals: 3) |> String.trim_trailing("0")
    end
  end
end
