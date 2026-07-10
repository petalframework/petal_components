defmodule PetalComponents.InputOtp do
  use Phoenix.Component

  @doc """
  A segmented one-time-code input.

  Under the hood there is exactly ONE real (invisible) input stretched across
  the painted segments, which is what makes everything work the way users
  expect: native paste, one form field posted, and SMS / password-manager
  autofill via `autocomplete="one-time-code"`. The `PetalInputOTP` hook
  (shipped in the petal_components JS bundle) paints the segments, the fake
  caret and the active ring.

  Fires a `petal:otp-complete` DOM event (bubbling, with `detail.value`) when
  all segments are filled; `phx-change` on the surrounding form works as
  normal.

  ## Examples

      <.input_otp name="code" />

      <.input_otp name="code" length={6} group_size={3} />

      <.input_otp name="pin" length={4} pattern="alphanumeric" />
  """
  attr :id, :string, default: nil
  attr :name, :string, required: true
  attr :value, :string, default: ""
  attr :length, :integer, default: 6
  attr :group_size, :integer, default: nil, doc: "splits segments into groups with a separator"

  attr :pattern, :string,
    default: "numeric",
    values: ["numeric", "alphanumeric"],
    doc: "which characters are accepted"

  attr :disabled, :boolean, default: false
  attr :class, :any, default: nil
  attr :rest, :global

  def input_otp(assigns) do
    assigns =
      assigns
      |> assign(:id, assigns.id || "pc-otp-#{assigns.name}")
      |> assign(:groups, slot_groups(assigns.length, assigns.group_size))

    ~H"""
    <div
      class={["pc-otp", @class]}
      id={@id}
      phx-hook="PetalInputOTP"
      data-pattern={@pattern}
      {@rest}
    >
      <input
        type="text"
        class="pc-otp__input"
        name={@name}
        id={@id <> "-input"}
        value={@value}
        maxlength={@length}
        inputmode={if @pattern == "numeric", do: "numeric", else: "text"}
        autocomplete="one-time-code"
        spellcheck="false"
        autocapitalize="off"
        disabled={@disabled}
        data-pc-otp-input
      />
      <div class="pc-otp__slots" aria-hidden="true">
        <%= for {group, index} <- Enum.with_index(@groups) do %>
          <div :if={index > 0} class="pc-otp__separator">-</div>
          <div class="pc-otp__group">
            <div :for={_slot <- group} class="pc-otp__slot" data-pc-otp-slot></div>
          </div>
        <% end %>
      </div>
    </div>
    """
  end

  defp slot_groups(length, nil), do: [Enum.to_list(1..length)]
  defp slot_groups(length, group_size), do: Enum.chunk_every(Enum.to_list(1..length), group_size)
end
