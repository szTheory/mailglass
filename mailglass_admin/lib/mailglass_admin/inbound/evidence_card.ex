defmodule MailglassAdmin.Inbound.EvidenceCard do
  @moduledoc """
  Evidence card (raw half) — raw provider source, default-redacted.

  NET-NEW chrome reuse. PII handling is determined by the schema: `raw_payload`
  and `raw_mime` are `redact: true` on `MailglassInbound.InboundRecords.InboundEvidence`
  (T-48-12). This card NEVER renders those bytes by default — it shows
  a provider-aware safe verification summary plus a redacted summary (provider,
  payload byte size, header count) and a masked placeholder for the raw body.

  Revealing the raw payload requires the `:reveal_raw` capability (the same
  `MailglassAdmin.Auth.authorize/3` seam as replay — no new auth surface).
  The InboundLive owns the authorization decision and passes `reveal_state` here:

    - `:redacted` — default; raw bytes absent, redacted placeholder shown.
    - `:revealed` — capability granted; raw payload rendered in a read-only
      `<pre class="mono text-label">` scroll region.
    - `:denied` — reveal attempted and denied; placeholder stays + brand-voice line.

  Raw source, once revealed, is read-only and never editable.
  """

  use Phoenix.Component

  import MailglassAdmin.Components, only: [card: 1]

  attr(:evidence, :map, default: nil)
  attr(:reveal_state, :atom, default: :redacted)
  attr(:can_reveal?, :boolean, default: true)

  def evidence_card(assigns) do
    ~H"""
    <.card
      padding={:lg}
      data-testid="inbound-evidence-card"
      data-group-card="inbound-evidence-card"
    >
      <div class="mb-md flex flex-wrap items-center justify-between gap-sm">
        <h3 class="text-body font-bold text-base-content">Raw provider source</h3>
        <%!-- True ARIA disclosure (D-11): the reveal trigger PERSISTS across the
              redacted -> revealed transition, toggling aria-expanded rather than
              being swapped out. aria-controls points at the raw region it governs;
              the re-redact control inside the revealed payload collapses it back.
              The "Raw source locked" badge + PII caption only show while collapsed. --%>
        <div :if={@evidence} class="flex flex-wrap items-center gap-sm">
          <span :if={@reveal_state != :revealed} class="badge badge-outline text-label">
            Raw source locked
          </span>
          <div class="flex flex-col items-end gap-xs">
            <button
              id="inbound-evidence-reveal-btn"
              type="button"
              phx-click="reveal_raw"
              data-testid="inbound-evidence-reveal"
              aria-expanded={if @reveal_state == :revealed, do: "true", else: "false"}
              aria-controls="inbound-evidence-raw"
              class="mg-focus-ring btn btn-ghost min-h-11 px-md"
            >
              {if @reveal_state == :revealed, do: "Raw source revealed", else: "Reveal raw source"}
            </button>
            <span :if={@reveal_state != :revealed} class="text-label text-secondary">
              Contains unredacted PII.
            </span>
          </div>
        </div>
      </div>

      <%= if is_nil(@evidence) do %>
        <p class="text-body text-secondary">
          No raw provider source has been stored for this message.
        </p>
      <% else %>
        <dl class="mb-md grid gap-sm text-body text-secondary sm:grid-cols-2">
          <div class="rounded-box border border-base-300 bg-base-100 px-sm py-xs">
            <dt class="text-label uppercase font-bold text-secondary">Provider</dt>
            <dd class="mono text-label text-base-content">{provider_label(@evidence.provider)}</dd>
          </div>
          <div class="rounded-box border border-base-300 bg-base-100 px-sm py-xs">
            <dt class="text-label uppercase font-bold text-secondary">Payload size</dt>
            <dd class="mono text-label text-base-content">{payload_byte_size(@evidence)} bytes</dd>
          </div>
          <div class="rounded-box border border-base-300 bg-base-100 px-sm py-xs">
            <dt class="text-label uppercase font-bold text-secondary">Header count</dt>
            <dd class="mono text-label text-base-content">{header_count(@evidence)}</dd>
          </div>
        </dl>

        <div class="mb-md space-y-xs" data-testid="inbound-evidence-verification">
          <p class="text-label uppercase font-bold text-secondary">
            Verification facts
          </p>
          <dl class="grid gap-sm text-body sm:grid-cols-2">
            <div class="rounded-box border border-base-300 bg-base-100 px-sm py-xs">
              <dt class="text-label text-secondary">Provider authentication</dt>
              <dd class="text-body text-base-content">{safe_verification_status(@evidence)}</dd>
            </div>
          </dl>
        </div>

        <%= case @reveal_state do %>
          <% :revealed -> %>
            <div class="space-y-xs">
              <div class="flex flex-wrap items-center justify-between gap-sm">
                <p class="text-label uppercase font-bold text-secondary">
                  Raw payload (read-only)
                </p>
                <button
                  type="button"
                  phx-click="re_redact_raw"
                  data-testid="inbound-evidence-re-redact"
                  class="mg-focus-ring btn btn-ghost min-h-11 px-sm"
                >
                  Re-redact raw source
                </button>
              </div>
              <pre
                data-testid="inbound-evidence-raw"
                class="mono max-h-80 overflow-auto rounded-box border border-base-300 bg-base-100 p-sm text-label text-base-content"
              ><%= raw_payload_text(@evidence) %></pre>
            </div>
          <% :denied -> %>
            <p
              data-testid="inbound-evidence-denied"
              class="rounded-box border border-warning bg-base-100 p-sm text-body text-base-content"
            >
              Raw source not revealed: the reveal_raw capability is not granted for this operator.
            </p>
          <% _redacted -> %>
            <p
              data-testid="inbound-evidence-redacted"
              class="mono rounded-box border border-base-300 bg-base-100 p-sm text-label text-secondary"
            >
              Raw source redacted. Revealing the raw provider payload requires the reveal_raw capability.
            </p>
        <% end %>

        <%!-- Reveal-state change is announced in TEXT, never the warning border
              color alone (WCAG 1.4.1, D-11). The region is always present so the
              announcement is perceived on the :revealed -> :redacted collapse too. --%>
        <p
          data-testid="inbound-evidence-status"
          role="status"
          aria-live="polite"
          class={["mt-sm text-body text-secondary", @reveal_state != :revealed && "sr-only"]}
        >
          {reveal_status_text(@reveal_state)}
        </p>
      <% end %>
    </.card>
    """
  end

  # Byte size of the stored raw payload (the JSON-encoded map). Computed from the
  # redacted field's structure WITHOUT exposing its contents — only a count.
  defp payload_byte_size(%{raw_payload: payload}) when is_map(payload) do
    payload |> Jason.encode!() |> byte_size()
  rescue
    _ -> 0
  end

  defp payload_byte_size(%{raw_mime: mime}) when is_binary(mime), do: byte_size(mime)
  defp payload_byte_size(_evidence), do: 0

  defp header_count(%{raw_headers: headers}) when is_map(headers), do: map_size(headers)
  defp header_count(_evidence), do: 0

  defp raw_payload_text(%{raw_payload: payload}) when is_map(payload) and map_size(payload) > 0 do
    Jason.encode!(payload, pretty: true)
  rescue
    _ -> inspect(payload, pretty: true)
  end

  defp raw_payload_text(%{raw_mime: mime}) when is_binary(mime) and mime != "", do: mime
  defp raw_payload_text(_evidence), do: "(empty)"

  defp provider_label(provider) when provider in [:mailgun, "mailgun"], do: "MAILGUN"
  defp provider_label(provider) when provider in [:postmark, "postmark"], do: "POSTMARK"
  defp provider_label(provider) when provider in [:sendgrid, "sendgrid"], do: "SENDGRID"
  defp provider_label(provider) when provider in [:ses, "ses"], do: "SES"
  defp provider_label(_provider), do: "UNKNOWN"

  defp safe_verification_status(%{provider: provider, verification_facts: facts})
       when provider in [:ses, "ses"] and is_map(facts) do
    case Map.get(facts, :auth, Map.get(facts, "auth")) do
      auth when auth in [:sns_x509, "sns_x509"] -> "SNS X.509 authentication verified"
      _unrecognized -> "Unavailable"
    end
  end

  defp safe_verification_status(_evidence), do: "Unavailable"

  # Text announced through the aria-live status region (WCAG 1.4.1, D-11). The
  # state change is perceivable in TEXT, never the warning border color alone.
  defp reveal_status_text(:revealed),
    do: "Raw source revealed. This payload contains unredacted PII."

  defp reveal_status_text(_redacted_or_denied), do: "Raw source re-redacted."
end
