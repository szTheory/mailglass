defmodule MailglassAdmin.Inbound.EvidenceCard do
  @moduledoc """
  Evidence card (raw half) — raw provider source, default-redacted.

  NET-NEW chrome reuse. PII handling is determined by the schema: `raw_payload`
  and `raw_mime` are `redact: true` on `MailglassInbound.InboundRecords.InboundEvidence`
  (T-48-12). This card NEVER renders those bytes by default — it shows
  one compact facts list of five truthful facts (provider, received time, payload
  size, header count, provider authentication) and withholds the raw body.

  Size and count are derived from stored evidence and are `nil` (rendered
  "Unavailable") when unknown, never "0". The checksum is deliberately not one of
  the five facts: `InboundEvidence` does store `raw_mime_sha256` and
  `raw_mime_fingerprint`, but the Phase 176 contract asks for five compact facts,
  so it is a scope choice, not an absence.

  Revealing the raw payload requires the `:reveal_raw` capability (the same
  `MailglassAdmin.Auth.authorize/3` seam as replay — no new auth surface).
  The InboundLive owns the authorization decision and passes `reveal_state` here:

    - `:redacted` — default; raw bytes absent, nothing but the disclosure button
      and the "May contain personal information." caption stand in for them.
    - `:revealed` — capability granted; raw payload rendered in a read-only
      `<pre class="mono text-label">` scroll region.
    - `:denied` — reveal attempted and denied; raw bytes stay absent + a
      `role="status"` brand-voice line.

  The header is one group: heading, caption and ONE persistent disclosure button
  ("Reveal raw source" / "Hide raw source", same element id, `aria-expanded`
  flips). The revealed `<pre>` is keyboard-scrollable (focusable).

  Raw source, once revealed, is read-only and never editable.
  """

  use Phoenix.Component

  import MailglassAdmin.Components, only: [card: 1, timestamp: 1]

  attr(:evidence, :map, default: nil)
  attr(:reveal_state, :atom, default: :redacted)
  attr(:received_at, :any, default: nil)

  def evidence_card(assigns) do
    ~H"""
    <.card
      padding={:lg}
      data-testid="inbound-evidence-card"
      data-group-card="inbound-evidence-card"
    >
      <%!-- One header group (D-24): heading, caption and a single PERSISTENT ARIA
            disclosure button. The button keeps the same id across collapsed and
            revealed so focus never moves; only its label, aria-expanded and
            phx-click change. Collapsed dispatches reveal_raw (authorized on the
            server at action time); revealed dispatches re_redact_raw (collapse
            only, never widens access). --%>
      <div class="mb-md flex flex-wrap items-start gap-sm">
        <div class="min-w-0 space-y-xs">
          <h3 class="text-body font-bold text-base-content">Raw provider source</h3>
          <p
            :if={@evidence}
            id="inbound-evidence-caption"
            data-testid="inbound-evidence-caption"
            class="text-label text-secondary"
          >
            May contain personal information.
          </p>
        </div>
        <button
          :if={@evidence}
          id="inbound-evidence-reveal-btn"
          type="button"
          phx-click={if @reveal_state == :revealed, do: "re_redact_raw", else: "reveal_raw"}
          data-testid="inbound-evidence-reveal"
          aria-expanded={if @reveal_state == :revealed, do: "true", else: "false"}
          aria-controls="inbound-evidence-raw"
          aria-describedby="inbound-evidence-caption"
          class="mg-focus-ring btn btn-ghost min-h-11 px-md border border-base-300 w-full sm:ml-auto sm:w-auto"
        >
          {if @reveal_state == :revealed, do: "Hide raw source", else: "Reveal raw source"}
        </button>
      </div>

      <%= if is_nil(@evidence) do %>
        <p class="text-body text-secondary">
          No raw provider source was stored for this message.
        </p>
      <% else %>
        <dl
          data-testid="inbound-evidence-facts"
          class="mb-md grid gap-md sm:grid-cols-2 lg:grid-cols-4"
        >
          <div class="min-w-0">
            <dt class="text-label font-bold text-secondary">Provider</dt>
            <dd class="mt-xs text-body text-base-content [overflow-wrap:anywhere] tabular-nums">
              {provider_label(@evidence.provider)}
            </dd>
          </div>
          <div class="min-w-0">
            <dt class="text-label font-bold text-secondary">Received</dt>
            <dd class="mt-xs text-body text-base-content [overflow-wrap:anywhere] tabular-nums">
              <.timestamp at={@received_at} />
            </dd>
          </div>
          <div class="min-w-0">
            <dt class="text-label font-bold text-secondary">Payload size</dt>
            <dd class="mt-xs text-body text-base-content [overflow-wrap:anywhere] tabular-nums">
              {format_bytes(payload_byte_size(@evidence))}
            </dd>
          </div>
          <div class="min-w-0">
            <dt class="text-label font-bold text-secondary">Header count</dt>
            <dd class="mt-xs text-body text-base-content [overflow-wrap:anywhere] tabular-nums">
              {format_count(header_count(@evidence))}
            </dd>
          </div>
          <div class="min-w-0" data-testid="inbound-evidence-verification">
            <dt class="text-label font-bold text-secondary">Provider authentication</dt>
            <dd class="mt-xs text-body text-base-content [overflow-wrap:anywhere] tabular-nums">
              {safe_verification_status(@evidence)}
            </dd>
          </div>
        </dl>

        <%= case @reveal_state do %>
          <% :revealed -> %>
            <pre
              id="inbound-evidence-raw"
              data-testid="inbound-evidence-raw"
              tabindex="0"
              aria-label="Raw provider source, read-only"
              class="mg-focus-ring mono max-h-80 overflow-auto rounded-box border border-base-300 bg-base-100 p-sm text-label text-base-content"
            ><%= raw_payload_text(@evidence) %></pre>
          <% :denied -> %>
            <p
              data-testid="inbound-evidence-denied"
              role="status"
              class="rounded-box border border-warning bg-base-100 p-sm text-body text-base-content"
            >
              You don't have permission to reveal raw source.
            </p>
          <% _redacted -> %>
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

  # Byte size of the stored evidence, or nil when it cannot be known (D-26).
  # Non-empty raw_mime wins (it is the stored source for MIME-backed providers),
  # then a non-empty raw_payload map (its JSON-encoded size). Known-empty storage
  # (empty map and no mime) is 0; anything else, including a failed encode, is nil
  # so unknown never reads as zero. Only a count is derived, never the contents.
  @spec payload_byte_size(map()) :: non_neg_integer() | nil
  defp payload_byte_size(%{raw_mime: mime}) when is_binary(mime) and mime != "",
    do: byte_size(mime)

  defp payload_byte_size(%{raw_payload: payload})
       when is_map(payload) and map_size(payload) > 0 do
    case Jason.encode(payload) do
      {:ok, json} -> byte_size(json)
      {:error, _reason} -> nil
    end
  rescue
    _ -> nil
  end

  defp payload_byte_size(%{raw_payload: payload} = evidence) when payload == %{} do
    if Map.get(evidence, :raw_mime) in [nil, ""], do: 0, else: nil
  end

  defp payload_byte_size(_evidence), do: nil

  @spec header_count(map()) :: non_neg_integer() | nil
  defp header_count(%{raw_headers: headers}) when is_map(headers), do: map_size(headers)
  defp header_count(_evidence), do: nil

  defp format_bytes(nil), do: "Unavailable"
  defp format_bytes(1), do: "1 byte"
  defp format_bytes(size) when is_integer(size), do: "#{delimit(size)} bytes"

  # Thousands separators for readability: 1234 -> "1,234".
  defp delimit(size) do
    size
    |> Integer.to_string()
    |> String.reverse()
    |> String.replace(~r/(\d{3})(?=\d)/, "\\1,")
    |> String.reverse()
  end

  defp format_count(nil), do: "Unavailable"
  defp format_count(count) when is_integer(count), do: Integer.to_string(count)

  defp raw_payload_text(%{raw_payload: payload}) when is_map(payload) and map_size(payload) > 0 do
    Jason.encode!(payload, pretty: true)
  rescue
    _ -> inspect(payload, pretty: true)
  end

  defp raw_payload_text(%{raw_mime: mime}) when is_binary(mime) and mime != "", do: mime
  defp raw_payload_text(_evidence), do: "Provider sent an empty payload."

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
    do: "Raw source revealed. It may contain personal information."

  defp reveal_status_text(_redacted_or_denied), do: "Raw source hidden."
end
