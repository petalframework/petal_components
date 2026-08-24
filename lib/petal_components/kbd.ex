defmodule PetalComponents.Kbd do
  @moduledoc """
  A keyboard-key chip: the little cap you put next to a menu item, in a command
  palette trigger, or down the side of a shortcuts cheat sheet.

  Renders semantic `<kbd>` elements, so screen readers and copy/paste both do
  the right thing. There is no interactive behaviour and no JavaScript.

      <.kbd>K</.kbd>
      <.kbd keys={["cmd", "K"]} />
      <.kbd keys={["ctrl", "shift", "P"]} separator="then" size="sm" />

  ## Single key vs sequence

  With the default slot you get exactly one `<kbd>` and whatever you put in it.
  With `keys` you get one `<kbd>` per key wrapped in a group, with the
  `separator` glyph rendered between them and hidden from assistive tech
  (the `<kbd>` elements already say what the shortcut is).

  ## The symbol map

  Known key names are folded to their glyph, case-insensitively. Anything the
  map does not know renders verbatim, so `<.kbd keys={["cmd", "K"]} />` gives
  you `⌘` and a literal `K`.

  | Names | Glyph |
  | --- | --- |
  | `cmd`, `command`, `meta`, `super`, `win` | `⌘` |
  | `shift` | `⇧` |
  | `alt`, `opt`, `option` | `⌥` |
  | `ctrl`, `control` | `⌃` |
  | `enter`, `return` | `↵` |
  | `esc`, `escape` | `Esc` |
  | `tab` | `⇥` |
  | `backspace` | `⌫` |
  | `delete`, `del` | `⌦` |
  | `space` | `␣` |
  | `up`, `down`, `left`, `right` | `↑` `↓` `←` `→` |
  | `pageup` / `pagedown` | `PgUp` / `PgDn` |
  | `capslock` | `⇪` |

  ## Related

  `PetalComponents.Typography.inline_code/1` is the sibling chip for code
  snippets in prose. Same cap radius, mono type instead of sans, and no key
  semantics. Use `<.kbd>` when the reader is meant to press something.
  """
  use Phoenix.Component

  # Case-insensitive names -> glyph. Private on purpose: the moduledoc table is
  # the contract, and unknown names fall through verbatim rather than raising,
  # so adding a name here is never a breaking change.
  @symbols %{
    "cmd" => "⌘",
    "command" => "⌘",
    "meta" => "⌘",
    "super" => "⌘",
    "win" => "⌘",
    "shift" => "⇧",
    "alt" => "⌥",
    "opt" => "⌥",
    "option" => "⌥",
    "ctrl" => "⌃",
    "control" => "⌃",
    "enter" => "↵",
    "return" => "↵",
    "esc" => "Esc",
    "escape" => "Esc",
    "tab" => "⇥",
    "backspace" => "⌫",
    "delete" => "⌦",
    "del" => "⌦",
    "space" => "␣",
    "up" => "↑",
    "arrowup" => "↑",
    "down" => "↓",
    "arrowdown" => "↓",
    "left" => "←",
    "arrowleft" => "←",
    "right" => "→",
    "arrowright" => "→",
    "pageup" => "PgUp",
    "pagedown" => "PgDn",
    "capslock" => "⇪"
  }

  attr :class, :any, default: nil, doc: "CSS class"

  attr :size, :string,
    default: "md",
    values: ["sm", "md"],
    doc: "chip size. sm is the dense variant for table rows and sidebars"

  attr :keys, :list,
    default: nil,
    doc:
      ~s|renders a key sequence with separator glyphs, e.g. keys={["cmd", "K"]}. Known names ("cmd", "shift", "alt", "ctrl", "enter", "esc", "tab", "backspace", arrows) map to their symbols; unknown strings render verbatim|

  attr :separator, :string,
    default: "+",
    doc: "glyph between keys in a sequence; nil renders the keys with no separator at all"

  attr :rest, :global, doc: "any extra HTML attributes, e.g. title or data-*"

  slot :inner_block, required: false, doc: "single-key content when keys is not used"

  @doc """
  A keyboard-key chip.

      <.kbd>K</.kbd>
      <.kbd keys={["cmd", "shift", "P"]} size="sm" />
  """
  def kbd(%{keys: keys} = assigns) when is_list(keys) do
    assigns = assign(assigns, :resolved, Enum.map(keys, &resolve/1))

    ~H"""
    <span class={["pc-kbd-group", @class]} {@rest}>
      <%= for {{glyph, name}, i} <- Enum.with_index(@resolved) do %>
        <span :if={i > 0 && @separator} class="pc-kbd-group__separator" aria-hidden="true">{@separator}</span>
        <kbd class={["pc-kbd", "pc-kbd--#{@size}"]} aria-label={name}>{glyph}</kbd>
      <% end %>
    </span>
    """
  end

  def kbd(assigns) do
    ~H"""
    <kbd class={["pc-kbd", "pc-kbd--#{@size}", @class]} {@rest}>{render_slot(@inner_block)}</kbd>
    """
  end

  # Screen reader handling of the bare glyphs is inconsistent (VoiceOver says
  # nothing at all for some of them), so symbol-mapped keys speak their
  # canonical names. Text renderings (Esc, PgUp...) read fine as-is.
  @names %{
    "⌘" => "Command",
    "⇧" => "Shift",
    "⌥" => "Option",
    "⌃" => "Control",
    "↵" => "Enter",
    "⇥" => "Tab",
    "⌫" => "Backspace",
    "⌦" => "Delete",
    "␣" => "Space",
    "↑" => "Arrow up",
    "↓" => "Arrow down",
    "←" => "Arrow left",
    "→" => "Arrow right",
    "⇪" => "Caps lock"
  }

  defp resolve(key) do
    key = to_string(key)
    glyph = Map.get(@symbols, String.downcase(key), key)
    {glyph, Map.get(@names, glyph)}
  end
end
