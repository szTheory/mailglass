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

  The Payload size fact and the revealed source come from ONE selector,
  `raw_source/1`: a non-empty `raw_payload` map wins, then a non-empty `raw_mime`
  binary. Size is the UTF-8 byte size of the exact text the reveal renders, so the
  fact and the `<pre>` always describe the same stored field. A record with
  nothing stored shows no reveal control, only the not-stored sentence (D-26).

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
            :if={@evidence && not nothing_stored?(@evidence)}
            id="inbound-evidence-caption"
            data-testid="inbound-evidence-caption"
            class="text-label text-secondary"
          >
            May contain personal information.
          </p>
        </div>
        <button
          :if={@evidence && not nothing_stored?(@evidence)}
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

        <%= if nothing_stored?(@evidence) do %>
          <%!-- D-26 "Not stored": nothing to disclose, so no reveal control, no
                caption, no <pre> and no status region; only the static sentence. --%>
          <p data-testid="inbound-evidence-not-stored" class="text-body text-secondary">
            No raw provider source was stored for this message.
          </p>
        <% else %>
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
      <% end %>
    </.card>
    """
  end

  # Byte size of the raw source the reveal shows, or nil when it cannot be known
  # (D-26). One selector, raw_source/1, drives both this size and the revealed
  # text, so the fact and the <pre> describe the same stored field.
  #
  # Precedence: a non-empty raw_payload map wins, then a non-empty raw_mime binary
  # (the pre-phase order, c96c8a4f, so the revealed bytes are unchanged, D-27).
  # Measurement: the UTF-8 byte size of the exact revealed text, i.e.
  # Jason.encode(payload, pretty: true) for a map and the binary itself for
  # raw_mime. Known-empty storage (empty map, no mime) is 0. Unknown storage and an
  # unencodable payload are nil ("Unavailable"), never 0: an unencodable payload
  # stays the selected source even beside a raw_mime, and its size is not measured
  # from the inspect/2 debugging text. Only a count is derived, never the contents.
  @spec payload_byte_size(map()) :: non_neg_integer() | nil
  defp payload_byte_size(evidence) do
    case evidence |> raw_source() |> raw_source_text() do
      {:ok, text} -> byte_size(text)
      :empty -> 0
      _unencodable_or_unknown -> nil
    end
  end

  @spec raw_source(map()) ::
          {:payload, map()} | {:mime, binary()} | :empty | :unknown
  defp raw_source(evidence) do
    payload = Map.get(evidence, :raw_payload)
    mime = Map.get(evidence, :raw_mime)

    cond do
      is_map(payload) and map_size(payload) > 0 -> {:payload, payload}
      is_binary(mime) and mime != "" -> {:mime, mime}
      payload == %{} and mime in [nil, ""] -> :empty
      true -> :unknown
    end
  end

  defp raw_source_text({:payload, payload}) do
    case Jason.encode(payload, pretty: true) do
      {:ok, json} -> {:ok, json}
      {:error, _reason} -> :unencodable
    end
  rescue
    _ -> :unencodable
  end

  defp raw_source_text({:mime, mime}), do: {:ok, mime}
  defp raw_source_text(:empty), do: :empty
  defp raw_source_text(:unknown), do: :unknown

  defp nothing_stored?(evidence), do: raw_source(evidence) == :unknown

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

  defp raw_payload_text(evidence) do
    source = raw_source(evidence)

    case raw_source_text(source) do
      {:ok, text} ->
        text

      :unencodable ->
        {:payload, payload} = source
        inspect(payload, pretty: true)

      :empty ->
        "Provider sent an empty payload."

      # Markup renders the <pre> only when something is stored; this clause keeps
      # unknown storage from ever claiming an empty payload.
      :unknown ->
        "No raw provider source was stored for this message."
    end
  end

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
