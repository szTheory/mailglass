defmodule MailglassAdmin.Inbound.ReplayModalTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MailglassAdmin.Inbound.ReplayModal

  describe "replay_modal/1" do
    test "renders a labelled dialog and certifies inbound has no replay target radio group" do
      html =
        render_component(&ReplayModal.replay_modal/1,
          open?: true,
          record: %{
            id: "rec-1",
            tenant_id: "tenant-a",
            envelope_recipient: "alice@example.com"
          }
        )

      assert html =~ ~s(data-testid="inbound-replay-modal")
      assert html =~ ~s(role="dialog")
      assert html =~ ~s(aria-modal="true")
      assert html =~ ~s(aria-labelledby="inbound-replay-modal-title")
      assert html =~ ~s(id="inbound-replay-modal-title")
      assert html =~ ~s(phx-click="close_replay")
      assert html =~ ~s(phx-click="confirm_replay")
      refute html =~ ~s(type="radio")
      refute html =~ "operator-replay-targets"
      refute html =~ "choose_replay_target"
    end
  end
end
