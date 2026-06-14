defmodule MailglassAdmin.Operator.DetailHeader do
  @moduledoc """
  Selected delivery summary header.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias MailglassAdmin.Operator.RepairState

  attr(:delivery, :map, required: true)
  attr(:replay_targets, :map, default: nil)
  attr(:latest_replay, :map, default: nil)

  def detail_header(assigns) do
    ~H"""
    <article data-testid="operator-detail-header" class="card rounded-box border border-base-300 bg-base-200 p-6">
      <div class="flex flex-wrap items-start justify-between gap-md">
        <div class="space-y-2">
          <div class="flex flex-wrap items-center gap-2">
            <h2 class="text-heading font-bold text-base-content">{@delivery.recipient}</h2>
            <Components.status_badge status={@delivery.status} />
          </div>
          <p class="mono text-label text-secondary">{@delivery.id}</p>
          <p :if={present?(@delivery.mailable)} class="text-body text-secondary">
            {@delivery.mailable}
          </p>
        </div>

        <dl class="grid gap-sm text-body text-secondary sm:grid-cols-2">
          <div>
            <dt class="text-label font-bold uppercase tracking-[0.08em]">Tenant</dt>
            <dd class="mt-1 text-base-content">{@delivery.tenant_id}</dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase tracking-[0.08em]">Provider</dt>
            <dd class="mt-1 text-base-content">{String.upcase(@delivery.provider || "unknown")}</dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase tracking-[0.08em]">Stream</dt>
            <dd class="mt-1 text-base-content">{label(@delivery.stream)}</dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase tracking-[0.08em]">Latest event</dt>
            <dd class="mt-1 text-base-content">{label(@delivery.last_event_type)}</dd>
          </div>
          <div>
            <dt class="text-label font-bold uppercase tracking-[0.08em]">Updated</dt>
            <dd class="mono mt-1 text-base-content">{format_datetime(@delivery.last_event_at)}</dd>
          </div>
          <div :if={present?(@delivery.provider_message_id)}>
            <dt class="text-label font-bold uppercase tracking-[0.08em]">Provider message</dt>
            <dd class="mono mt-1 text-base-content">{@delivery.provider_message_id}</dd>
          </div>
        </dl>
      </div>

      <div class="mt-6 flex flex-wrap items-start justify-between gap-md border-t border-base-300 pt-4">
        <div class="space-y-1">
          <h3 class="text-body font-bold uppercase tracking-[0.08em] text-secondary">Webhook replay</h3>
          <p class="text-body text-base-content">{RepairState.availability_hint(@replay_targets)}</p>
          <p :if={@latest_replay} class="text-label text-secondary">
            Last replay: {RepairState.latest_replay_summary(@latest_replay)} at {format_datetime(@latest_replay.occurred_at)}
          </p>
        </div>

        <button
          type="button"
          phx-click="open_replay"
          data-testid="operator-replay-open"
          class="btn btn-error min-h-11 px-5"
        >
          Replay webhook
        </button>
      </div>
    </article>
    """
  end

  defp label(nil), do: "Unknown"

  defp label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_datetime(nil), do: "Pending"

  defp format_datetime(%DateTime{} = datetime),
    do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")

  defp present?(value), do: value not in [nil, ""]
end
