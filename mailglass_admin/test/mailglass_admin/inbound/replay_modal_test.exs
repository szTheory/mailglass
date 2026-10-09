defmodule MailglassAdmin.Inbound.ReplayModalTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MailglassAdmin.Inbound.ReplayModal

  describe "replay_modal/1" do
    test "renders a labelled dialog and certifies inbound has no replay target radio group" do
      html =
        render_component(&ReplayModal.replay_modal/1,
          open?: true,
          review: %{
            tenant_id: "tenant-a",
            record_id: "rec-1",
            eligibility: %{status: :eligible, mailbox: "Elixir.MyApp.Mailboxes.SupportMailbox"}
          },
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
      assert html =~ "rec-1"
      assert html =~ "Recorded Mailbox: Elixir.MyApp.Mailboxes.SupportMailbox"
      assert html =~ "currently deployed code against the stored InboundMessage"
      assert html =~ "does not evaluate current router rules or redeliver through the provider"
      assert html =~ ~s(phx-click="close_replay")
      confirm_button = Floki.find(Floki.parse_document!(html), "#inbound-replay-confirm")
      assert Floki.attribute(confirm_button, "phx-click") |> List.first() =~ "confirm_replay"
      refute html =~ "Re-runs Mailbox routing"
      refute html =~ ~s(disabled="disabled")
      refute html =~ ~s(type="radio")
      refute html =~ "operator-replay-targets"
      refute html =~ "choose_replay_target"
    end

    test "renders the cause and disables confirmation for an ineligible target" do
      html =
        render_component(&ReplayModal.replay_modal/1,
          open?: true,
          review: %{
            tenant_id: "tenant-a",
            record_id: "rec-1",
            eligibility: %{status: :ineligible, reason: :execution_history_missing}
          },
          record: %{
            id: "rec-1",
            tenant_id: "tenant-a",
            envelope_recipient: "alice@example.com"
          }
        )

      assert html =~ "No execution history is recorded for this message"

      confirm_button = Floki.find(Floki.parse_document!(html), "#inbound-replay-confirm")
      assert Floki.attribute(confirm_button, "disabled") != []
    end

    test "keeps duplicate confirmation disabled while the local command is pending" do
      html =
        render_component(&ReplayModal.replay_modal/1,
          open?: true,
          busy?: true,
          review: %{
            tenant_id: "tenant-a",
            record_id: "rec-1",
            eligibility: %{status: :eligible, mailbox: "Elixir.MyApp.Mailboxes.SupportMailbox"}
          },
          record: %{id: "rec-1", tenant_id: "tenant-a"}
        )

      confirm_button = Floki.find(Floki.parse_document!(html), "#inbound-replay-confirm")
      assert Floki.attribute(confirm_button, "disabled") != []
      assert Floki.text(confirm_button) =~ "Replaying"
      refute html =~ "locked globally"
      refute html =~ "retry"
    end
  end
end
