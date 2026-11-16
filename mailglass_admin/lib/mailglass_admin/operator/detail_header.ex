defmodule MailglassAdmin.Operator.DetailHeader do
  @moduledoc """
  Selected delivery summary header.
  """

  use Phoenix.Component

  alias MailglassAdmin.Components
  alias MailglassAdmin.Copy
  alias MailglassAdmin.Operator.Accounts
  alias MailglassAdmin.Operator.MailerName

  attr(:delivery, :map, required: true)
  attr(:account_labels, :map, default: %{})
  # The evidence the verdict may read: the loaded timeline and the suppression match.
  # A read that did not succeed is passed on as such, so the verdict never shows a
  # cause or the no-reason fallback for history it could not read.
  attr(:timeline_events, :list, default: [])
  attr(:timeline_state, :atom, default: :ready)
  attr(:suppression_state, :map, default: nil)
  attr(:suppression_read_state, :atom, default: :ready)

  def detail_header(assigns) do
    mailable = Map.get(assigns.delivery, :mailable)

    assigns =
      assigns
      |> assign(:mailer_name, MailerName.plain_name(mailable))
      |> assign(:mailer_identity, MailerName.identity(mailable))

    ~H"""
    <Components.card
      padding={:lg}
      data-testid="operator-detail-header"
      data-group-card="operator-detail-header"
    >
      <div class="min-w-0 space-y-lg">
        <Components.message_identity
          subject={Map.get(@delivery, :subject)}
          recipient={@delivery.recipient}
          status={Components.delivery_display_status(@delivery)}
          delivery_row={@delivery}
          context={:delivery}
          id="delivery-detail-outcome"
        />
        <Components.delivery_verdict
          form={:full}
          id="delivery-detail-verdict"
          verdict={
            Copy.delivery_verdict(@delivery, %{
              events: events_evidence(@timeline_state, @timeline_events),
              suppression: suppression_evidence(@suppression_read_state, @suppression_state)
            })
          }
        />
        <dl class="grid min-w-0 gap-md text-body text-secondary sm:grid-cols-2 lg:grid-cols-4 [&>div]:min-w-0 [&_dd]:[overflow-wrap:anywhere]">
          <%!-- The mailer is a fact a reader needs without opening anything: the plain name
              is the help trigger, the stored identity is its tooltip and is also printed
              below it, so a touch reader never depends on hover (D-13). No `title`. --%>
          <div :if={@mailer_name} data-testid="operator-detail-mailer">
            <dt class="text-label font-bold">Mailer</dt>
            <dd class="mt-xs text-base-content">
              <Components.field_help
                id="delivery-detail-mailer"
                label={@mailer_name}
                text={@mailer_identity}
                trigger_text={@mailer_name}
                trigger_class="text-base-content"
              />
              <span
                data-testid="operator-detail-mailer-identity"
                class="mono block break-words text-label text-secondary"
              >
                {@mailer_identity}
              </span>
            </dd>
          </div>
          <div>
            <dt class="text-label font-bold">Provider</dt>
            <dd class="mt-xs text-base-content">{String.upcase(@delivery.provider || "unknown")}</dd>
          </div>
          <div>
            <dt class="text-label font-bold">Stream</dt>
            <dd class="mt-xs text-base-content">{label(@delivery.stream)}</dd>
          </div>
          <div>
            <dt class="text-label font-bold">Updated</dt>
            <dd class="mt-xs text-base-content">
              <Components.timestamp at={@delivery.last_event_at} />
            </dd>
          </div>
          <div>
            <dt class="text-label font-bold">Account</dt>
            <dd
              class="mt-xs text-base-content"
              title={Accounts.title(@delivery.tenant_id, @account_labels)}
            >
              {Accounts.label(@delivery.tenant_id, @account_labels)}
            </dd>
          </div>
          <div :if={Components.latest_event_differs?(@delivery)}>
            <dt class="text-label font-bold">Latest event</dt>
            <dd class="mt-xs text-base-content">{label(@delivery.last_event_type)}</dd>
          </div>
        </dl>
        <Components.technical_details
          collapsible={true}
          id="delivery-detail-technical"
        >
          <div>
            <dt class="text-label font-bold text-secondary">Delivery ID</dt>
            <dd class="mt-xs"><Components.copy_value value={@delivery.id} label="Delivery ID" /></dd>
          </div>
          <div :if={present?(@delivery.provider_message_id)}>
            <dt class="text-label font-bold text-secondary">Provider message ID</dt>
            <dd class="mt-xs">
              <Components.copy_value
                value={@delivery.provider_message_id}
                label="Provider message ID"
              />
            </dd>
          </div>
        </Components.technical_details>
      </div>
    </Components.card>
    """
  end

  defp events_evidence(:ready, events) when is_list(events), do: events
  defp events_evidence(_state, _events), do: :read_failed

  defp suppression_evidence(read_state, %{} = state)
       when read_state in [:ready, :stale] and map_size(state) > 0,
       do: %{reason: Map.get(state, :reason)}

  # The read succeeded and no entry matches: an entry that expired or was removed. That
  # is the absence of an entry, not an entry with no reason (an entry always has one).
  defp suppression_evidence(:ready, _state), do: :no_entry
  defp suppression_evidence(_read_state, _state), do: :read_failed

  defp label(nil), do: "Unknown"

  defp label(value) do
    value
    |> Atom.to_string()
    |> String.replace("_", " ")
    |> String.capitalize()
  end

  defp present?(value), do: value not in [nil, ""]
end
