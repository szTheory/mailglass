defmodule Storybook.DeliveryInvestigation do
  @moduledoc false
  use PhoenixStorybook.Story, :page

  alias MailglassAdmin.Operator.DetailHeader
  alias MailglassAdmin.Operator.ReplayAction
  alias MailglassAdmin.Operator.ReplayModal
  alias MailglassAdmin.Operator.SuppressionCard

  def doc,
    do:
      "First complete Delivery investigation composition. Synthetic facts only; controls do not execute refresh or replay commands."

  def render(assigns) do
    scenario = MailglassDemo.QuickViewScenarios.delivery(:northstar_normal)
    delivery = Map.merge(scenario.delivery, %{stream: :transactional})
    observed_at = ~U[2026-10-27 12:00:00Z]

    suppression_state = %{
      address: "alex@example.test",
      scope: :address_stream,
      reason: :complained,
      source: :provider_event,
      stream: :transactional,
      expires_at: ~U[2026-11-03 12:00:00Z],
      removal_policy: :blocked
    }

    replay_targets = %{
      status: :exact,
      candidate: %{
        webhook_event_id: "wh_evt_story_delivery_01",
        provider_event_id: "evt_story_delivery_01",
        delivery_provider_message_id: delivery.provider_message_id,
        provider: delivery.provider,
        webhook_timestamp: observed_at
      }
    }

    assigns =
      Map.merge(assigns, %{
        delivery: delivery,
        account_labels: scenario.account_labels,
        suppression_state: suppression_state,
        replay_targets: replay_targets,
        review_id: "story-only-review"
      })

    ~H"""
    <main data-theme="mailglass-light" class="mg-admin-root min-h-screen space-y-4 bg-base-100 p-lg text-base-content">
      <header class="space-y-xs">
        <p class="text-label font-bold text-secondary">Retained production composition</p>
        <h1 class="text-display font-bold text-base-content">Delivery investigation</h1>
        <p class="max-w-prose text-body text-secondary">
          Bounded synthetic facts show primary Delivery facts, scoped suppression, and exact webhook review.
          This page does not run server commands.
        </p>
      </header>

      <DetailHeader.detail_header delivery={@delivery} account_labels={@account_labels} />
      <SuppressionCard.suppression_card suppression_state={@suppression_state} read_state={:ready} />
      <ReplayAction.replay_action replay_targets={@replay_targets} />
      <ReplayModal.replay_modal
        open?={true}
        delivery={@delivery}
        replay_targets={@replay_targets}
        selected_target_id={@replay_targets.candidate.webhook_event_id}
        review_id={@review_id}
        account_label={MailglassAdmin.Operator.Accounts.label(@delivery.tenant_id, @account_labels)}
      />
    </main>
    """
  end
end
