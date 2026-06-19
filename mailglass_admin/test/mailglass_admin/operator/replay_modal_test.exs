defmodule MailglassAdmin.Operator.ReplayModalTest do
  use ExUnit.Case, async: true

  import Phoenix.LiveViewTest

  alias MailglassAdmin.Operator.ReplayModal

  describe "replay_modal/1 ambiguous target controls" do
    test "renders native radios with stable IDs, labels, descriptions, and selected text" do
      first = candidate("webhook-a", "provider-a")
      second = candidate("webhook-b", "provider-b")

      html =
        render_component(&ReplayModal.replay_modal/1,
          open?: true,
          delivery: %{recipient: "operator@example.com"},
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
      assert html =~ "hero-check-circle"
      assert html =~ ~s(phx-click="close_replay")
      assert html =~ ~s(phx-click="confirm_replay")
    end

    test "exact target branch stays non-radio and keeps confirm replay available" do
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

      assert html =~ "Replay is <span class=\"font-bold\">ready</span>"
      assert html =~ "provider-exact"
      assert html =~ ~s(data-testid="operator-replay-confirm")
      refute html =~ ~s(type="radio")
      refute html =~ ~s(id="operator-replay-targets")
      refute html =~ ~s(phx-change="choose_replay_target")
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
