defmodule Storybook.DeliveryInvestigation do
  @moduledoc false
  use PhoenixStorybook.Story, :component
  use Phoenix.Component

  alias MailglassAdmin.Operator.DetailHeader
  alias MailglassAdmin.Operator.ReplayAction
  alias MailglassAdmin.Operator.ReplayModal
  alias MailglassAdmin.Operator.SuppressionCard
  alias MailglassDemo.QuickViewScenarios

  def container, do: :iframe

  def template do
    """
    <div data-theme-owner="delivery-investigation-story" data-theme-preference="system" data-theme-resolved="light" data-theme-os="light" data-theme="mailglass-light" style="min-height: 900px" class="mg-admin-root bg-base-100 p-md text-base-content">
      <fieldset aria-label="Review theme" data-testid="delivery-investigation-review-theme" style="position: fixed; top: 8px; left: 8px; z-index: 1000; display: flex; flex-wrap: wrap; max-width: calc(100% - 16px); gap: 4px; margin: 0; padding: 4px; border: 1px solid var(--color-base-300); border-radius: 8px; background: var(--color-base-100); color: var(--color-base-content); box-shadow: 0 2px 8px rgb(13 27 42 / 18%);">
        <legend style="padding: 0 4px;">Review theme</legend>
        <label style="display: flex; align-items: center; gap: 4px; min-width: 64px; min-height: 44px; padding: 0 6px; cursor: pointer;"><input type="radio" name="delivery-investigation-review-theme" value="light" style="width: 16px; height: 16px;">Light</label>
        <label style="display: flex; align-items: center; gap: 4px; min-width: 64px; min-height: 44px; padding: 0 6px; cursor: pointer;"><input type="radio" name="delivery-investigation-review-theme" value="dark" style="width: 16px; height: 16px;">Dark</label>
        <label style="display: flex; align-items: center; gap: 4px; min-width: 64px; min-height: 44px; padding: 0 6px; cursor: pointer;"><input type="radio" name="delivery-investigation-review-theme" value="system" checked style="width: 16px; height: 16px;">System</label>
      </fieldset>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    for id <- [
          :northstar_complete,
          :fjordline_long_unicode,
          :suppression_stale,
          :suppression_unavailable,
          :unknown_expiry,
          :replay_ambiguous,
          :replay_unavailable,
          :replay_denied,
          :replay_failed
        ] do
      %Variation{id: id, attributes: QuickViewScenarios.delivery_investigation(id)}
    end
  end

  def render_case(assigns) do
    ~H"""
    <main
      data-testid="delivery-investigation-story"
      data-scenario-id={@scenario_id}
      data-state={@state}
      class="mx-auto max-w-6xl space-y-md p-md"
    >
      <header class="space-y-xs">
        <p class="text-label font-bold text-secondary">Retained production composition</p>
        <h1 class="text-display font-bold text-base-content">Delivery investigation</h1>
        <p class="max-w-prose text-body text-secondary">{@role_job}</p>
        <p class="text-label text-secondary">Static rendering only. Refresh and replay actions are not connected to commands.</p>
      </header>

      <DetailHeader.detail_header delivery={@delivery} account_labels={@account_labels} />
      <SuppressionCard.suppression_card
        suppression_state={@suppression_state}
        read_state={@suppression_read_state}
      />
      <ReplayAction.replay_action replay_targets={@replay_targets} />
      <ReplayModal.replay_modal
        open?={@modal_open?}
        delivery={@delivery}
        replay_targets={@replay_targets}
        selected_target_id={@selected_target_id}
        review_id={@review_id}
        account_label={MailglassAdmin.Operator.Accounts.label(@delivery.tenant_id, @account_labels)}
        feedback={@feedback}
        pending?={@pending?}
        consumed?={@consumed?}
      />
    </main>
    """
  end

  def function, do: &__MODULE__.render_case/1
end
