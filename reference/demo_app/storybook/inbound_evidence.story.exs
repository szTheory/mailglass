defmodule Storybook.InboundEvidence do
  @moduledoc false
  use PhoenixStorybook.Story, :component
  use Phoenix.Component

  alias MailglassAdmin.Inbound.DetailHeader
  alias MailglassAdmin.Inbound.EvidenceCard
  alias MailglassDemo.QuickViewScenarios

  def container, do: :iframe

  def template do
    """
    <div data-theme-owner="inbound-evidence-story" data-theme-preference="system" data-theme-resolved="light" data-theme-os="light" data-theme="mailglass-light" style="min-height: 900px" class="mg-admin-root bg-base-100 p-md text-base-content">
      <style>
        [data-theme-owner="inbound-evidence-story"] .inbound-evidence-story-content { padding-block-start: 104px; }
      </style>
      <fieldset aria-label="Review theme" data-testid="inbound-evidence-review-theme" style="position: fixed; top: 8px; left: 8px; z-index: 1000; display: flex; flex-wrap: wrap; max-width: calc(100% - 16px); gap: 4px; margin: 0; padding: 4px; border: 1px solid var(--color-base-300); border-radius: 8px; background: var(--color-base-100); color: var(--color-base-content); box-shadow: var(--shadow-overlay);">
        <legend style="padding: 0 4px;">Review theme</legend>
        <label style="display: flex; align-items: center; gap: 4px; min-width: 64px; min-height: 44px; padding: 0 6px; cursor: pointer;"><input type="radio" name="inbound-evidence-review-theme" value="light" style="width: 16px; height: 16px;">Light</label>
        <label style="display: flex; align-items: center; gap: 4px; min-width: 64px; min-height: 44px; padding: 0 6px; cursor: pointer;"><input type="radio" name="inbound-evidence-review-theme" value="dark" style="width: 16px; height: 16px;">Dark</label>
        <label style="display: flex; align-items: center; gap: 4px; min-width: 64px; min-height: 44px; padding: 0 6px; cursor: pointer;"><input type="radio" name="inbound-evidence-review-theme" value="system" checked style="width: 16px; height: 16px;">System</label>
      </fieldset>
      <.psb-variation/>
    </div>
    """
  end

  def variations do
    for id <- [
          :normal_contacts,
          :long_local_part,
          :unicode,
          :spoofed_display_name,
          :many_recipients,
          :missing_headers,
          :unparseable,
          :evidence_unknown,
          :evidence_empty_revealed,
          :evidence_large_revealed,
          :evidence_denied
        ] do
      %Variation{id: id, attributes: QuickViewScenarios.inbound_evidence(id)}
    end
  end

  def render_case(assigns) do
    ~H"""
    <main
      data-testid="inbound-evidence-story"
      data-scenario-id={@scenario_id}
      data-state={@state}
      class="inbound-evidence-story-content mx-auto max-w-6xl space-y-md px-md pb-md"
    >
      <header class="space-y-xs">
        <p class="text-label font-bold text-secondary">Retained production composition</p>
        <h1 class="text-display font-bold text-base-content">Inbound contacts and raw source</h1>
        <p class="max-w-prose text-body text-secondary">{@role_job}</p>
        <p class="text-label text-secondary">
          Static rendering only. Reveal is not connected to authorization.
        </p>
      </header>

      <DetailHeader.detail_header detail={@detail} account_labels={@account_labels} />
      <EvidenceCard.evidence_card
        evidence={@evidence}
        reveal_state={@reveal_state}
        received_at={@received_at}
      />
    </main>
    """
  end

  def function, do: &__MODULE__.render_case/1
end
