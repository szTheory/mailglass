defmodule MailglassAdmin.Operator.ReplayModalTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MailglassAdmin.Operator.ReplayModal

  describe "replay_modal/1 exact target review" do
    test "renders native radios with stable IDs, labels, descriptions, and selected text" do
      first = candidate("webhook-a", "provider-a")
      second = candidate("webhook-b", "provider-b")

      html =
        render_component(&ReplayModal.replay_modal/1,
          open?: true,
          delivery: %{recipient: "operator@example.com"},
          account_label: "Northstar Logistics",
          replay_targets: %{status: :ambiguous, candidates: [first, second]},
          selected_target_id: second.webhook_event_id
        )

      assert html =~ ~s(id="operator-replay-targets")
      assert html =~ ~s(phx-change="choose_replay_target")
      assert html =~ ~s(id="operator-replay-target-webhook-a")
      assert html =~ ~s(for="operator-replay-target-webhook-a")
      assert html =~ ~s(aria-describedby="operator-replay-target-webhook-a-description")
      assert html =~ ~s(name="webhook_event_id")
      assert html =~ ~s(value="webhook-a")
      assert html =~ ~s(id="operator-replay-target-webhook-b")
      assert html =~ ~s(for="operator-replay-target-webhook-b")
      assert html =~ ~s(aria-describedby="operator-replay-target-webhook-b-description")
      assert html =~ "Provider event provider-b"
      assert html =~ "Webhook event webhook-b"
      assert html =~ "Selected target"
      assert html =~ "Review webhook replay"
      assert html =~ "Northstar Logistics"
      assert html =~ "full stored request"
      assert html =~ "does not resend outbound mail"
      assert html =~ "Reviewed request"
      assert html =~ "hero-check-circle"
      assert html =~ ~s(phx-click="close_replay")
      assert html =~ ~s(data-testid="operator-replay-confirm")
      assert html =~ "confirm_replay"
    end

    test "exact target branch stays non-radio and keeps confirm replay available" do
      html =
        render_component(&ReplayModal.replay_modal/1,
          open?: true,
          delivery: %{recipient: "operator@example.com"},
          account_label: "Northstar Logistics",
          replay_targets: %{
            status: :exact,
            candidate: candidate("webhook-exact", "provider-exact")
          },
          selected_target_id: "webhook-exact"
        )

      assert html =~ "Review the exact stored request before confirming."
      assert html =~ "provider-exact"
      assert html =~ "Northstar Logistics"
      assert html =~ ~s(data-testid="operator-replay-confirm")
      refute html =~ ~s(type="radio")
      refute html =~ ~s(id="operator-replay-targets")
      refute html =~ ~s(phx-change="choose_replay_target")
    end

    test "exact target without a frozen id cannot be confirmed" do
      html =
        render_component(&ReplayModal.replay_modal/1,
          open?: true,
          delivery: %{recipient: "operator@example.com"},
          replay_targets: %{
            status: :exact,
            candidate: candidate("webhook-exact", "provider-exact")
          },
          selected_target_id: nil
        )

      refute html =~ ~s(data-testid="operator-replay-confirm")
    end

    test "pending and consumed reviews disable duplicate confirmation without claiming cancellation" do
      html =
        render_component(&ReplayModal.replay_modal/1,
          open?: true,
          delivery: %{recipient: "operator@example.com"},
          replay_targets: %{
            status: :exact,
            candidate: candidate("webhook-exact", "provider-exact")
          },
          selected_target_id: "webhook-exact",
          pending?: true,
          consumed?: true
        )

      assert html =~ "Replaying the reviewed request…"
      assert html =~ "Replaying…"
      assert html =~ " disabled"
      assert html =~ "Close replay review"
      refute html =~ "cancelled"
    end
  end

  defp candidate(webhook_event_id, provider_event_id) do
    %{
      provider: "postmark",
      webhook_event_id: webhook_event_id,
      webhook_timestamp: ~U[2026-06-19 12:00:00Z],
      provider_event_id: provider_event_id,
      delivery_provider_message_id: "delivery-#{webhook_event_id}"
    }
  end
end
