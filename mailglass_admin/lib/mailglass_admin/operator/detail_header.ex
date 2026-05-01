defmodule MailglassAdmin.Operator.DetailHeader do
  @moduledoc """
  Selected delivery summary header.
  """

  use Phoenix.Component

  attr :delivery, :map, required: true

  def detail_header(assigns) do
    ~H"""
    <article class="card rounded-box border border-base-300 bg-base-200 p-6">
      <div class="flex flex-wrap items-start justify-between gap-4">
        <div class="space-y-2">
          <div class="flex flex-wrap items-center gap-2">
            <h2 class="text-xl font-bold text-base-content">{@delivery.recipient}</h2>
            <span class={["badge", badge_class(@delivery.status)]}>
              {label(@delivery.status)}
            </span>
          </div>
          <p class="mono text-xs text-secondary">{@delivery.id}</p>
          <p :if={present?(@delivery.mailable)} class="text-sm text-secondary">
            {@delivery.mailable}
          </p>
        </div>

        <dl class="grid gap-3 text-sm text-secondary sm:grid-cols-2">
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Tenant</dt>
            <dd class="mt-1 text-base-content">{@delivery.tenant_id}</dd>
          </div>
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Provider</dt>
            <dd class="mt-1 text-base-content">{String.upcase(@delivery.provider || "unknown")}</dd>
          </div>
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Stream</dt>
            <dd class="mt-1 text-base-content">{label(@delivery.stream)}</dd>
          </div>
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Latest event</dt>
            <dd class="mt-1 text-base-content">{label(@delivery.last_event_type)}</dd>
          </div>
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Updated</dt>
            <dd class="mono mt-1 text-base-content">{format_datetime(@delivery.last_event_at)}</dd>
          </div>
          <div :if={present?(@delivery.provider_message_id)}>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Provider message</dt>
            <dd class="mono mt-1 text-base-content">{@delivery.provider_message_id}</dd>
          </div>
        </dl>
      </div>
    </article>
    """
  end

  defp badge_class(status) when status in [:delivered, :sent, :dispatched], do: "badge-success"
  defp badge_class(:deferred), do: "badge-warning"
  defp badge_class(status) when status in [:failed, :bounced, :complained], do: "badge-error"
  defp badge_class(:suppressed), do: "badge-warning"
  defp badge_class(_status), do: "badge-outline"

  defp label(nil), do: "Unknown"

  defp label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp format_datetime(nil), do: "Pending"
  defp format_datetime(%DateTime{} = datetime), do: Calendar.strftime(datetime, "%Y-%m-%d %H:%M:%S UTC")

  defp present?(value), do: value not in [nil, ""]
end
