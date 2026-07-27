defmodule PetalComponents.ToastTest do
  use ComponentCase
  import PetalComponents.Toast

  describe "toast_group/1" do
    test "renders the hook mount point with config data attributes" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toast_group />
        """)

      assert html =~ ~s(phx-hook="PetalToast")
      assert html =~ ~s(data-position="bottom-right")
      assert html =~ ~s(data-max="3")
      assert html =~ ~s(data-duration="5000")
      assert html =~ "pc-toast-group--bottom-right"
      assert html =~ ~s(role="region")
      # the stack the hook owns is shielded from patches
      assert html =~ ~s(phx-update="ignore")
    end

    test "position and tuning attrs flow through" do
      assigns = %{}

      html =
        rendered_to_string(~H"""
        <.toast_group position="top-center" max={5} duration={8000} />
        """)

      assert html =~ "pc-toast-group--top-center"
      assert html =~ ~s(data-max="5")
      assert html =~ ~s(data-duration="8000")
    end

    test "flash serialises onto the bridge attribute" do
      assigns = %{flash: %{"info" => "Saved!"}}

      html =
        rendered_to_string(~H"""
        <.toast_group flash={@flash} />
        """)

      assert html =~ "data-flash="
      assert html =~ "Saved!"
    end
  end

  describe "dismiss_toast/2" do
    test "pushes dismissal by id and for all" do
      socket = %Phoenix.LiveView.Socket{}

      by_id = dismiss_toast(socket, "export")

      assert [["petal:toast-dismiss", %{id: "export"}]] =
               Phoenix.LiveView.Utils.get_push_events(by_id)

      all = dismiss_toast(socket, :all)
      assert [["petal:toast-dismiss", %{all: true}]] = Phoenix.LiveView.Utils.get_push_events(all)
    end
  end

  describe "send_toast/3" do
    test "pushes the petal:toast event with a normalised payload" do
      socket = %Phoenix.LiveView.Socket{}
      socket = send_toast(socket, :error, title: "Nope", duration: :infinity)

      assert {:ok, %{events: [["petal:toast", payload]]}} =
               Phoenix.LiveView.Utils.get_push_events(socket) |> then(&{:ok, %{events: &1}})

      assert payload.kind == :danger
      assert payload.duration == 0
      assert payload.title == "Nope"
    end
  end
end
