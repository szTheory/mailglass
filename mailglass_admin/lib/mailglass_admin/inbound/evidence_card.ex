defmodule MailglassAdmin.Inbound.EvidenceCard do
  @moduledoc """
  Evidence card (IADM-02 raw half) — raw provider source, default-redacted.

  NET-NEW chrome reuse. PII handling is determined by the schema: `raw_payload`
  and `raw_mime` are `redact: true` on `MailglassInbound.InboundRecords.InboundEvidence`
  (T-48-12). This card NEVER renders those bytes by default — it shows
  `verification_facts` plus a redacted summary (provider, payload byte size,
  header count) and a masked placeholder for the raw body.

  Revealing the raw payload requires the `:reveal_raw` capability (the same
  `MailglassAdmin.Auth.authorize/3` seam as replay — no new auth surface, D-48-09).
  The InboundLive owns the authorization decision and passes `reveal_state` here:

    - `:redacted` — default; raw bytes absent, redacted placeholder shown.
    - `:revealed` — capability granted; raw payload rendered in a read-only
      `<pre class="mono text-xs">` scroll region.
    - `:denied` — reveal attempted and denied; placeholder stays + brand-voice line.

  Raw source, once revealed, is read-only and never editable.
  """

  use Phoenix.Component

  attr :evidence, :map, default: nil
  attr :reveal_state, :atom, default: :redacted
  attr :can_reveal?, :boolean, default: true

  def evidence_card(assigns) do
    ~H"""
    <article
      data-testid="inbound-evidence-card"
      class="card rounded-box border border-base-300 bg-base-200 p-6"
    >
      <div class="mb-4 flex flex-wrap items-center justify-between gap-3">
        <h3 class="text-base font-bold text-base-content">Raw provider source</h3>
        <button
          :if={@evidence && @reveal_state != :revealed}
          type="button"
          phx-click="reveal_raw"
          data-testid="inbound-evidence-reveal"
          class="btn btn-ghost btn-sm min-h-11 px-4"
        >
          Reveal raw source
        </button>
      </div>

      <%= if is_nil(@evidence) do %>
        <p class="text-sm text-secondary">
          No raw provider source has been stored for this message.
        </p>
      <% else %>
        <dl class="mb-4 grid gap-3 text-sm text-secondary sm:grid-cols-3">
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Provider</dt>
            <dd class="mt-1 text-base-content">{String.upcase(@evidence.provider || "unknown")}</dd>
          </div>
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Payload size</dt>
            <dd class="mono mt-1 text-base-content">{payload_byte_size(@evidence)} bytes</dd>
          </div>
          <div>
            <dt class="text-xs font-bold uppercase tracking-[0.08em]">Header count</dt>
            <dd class="mono mt-1 text-base-content">{header_count(@evidence)}</dd>
          </div>
        </dl>

        <div :if={map_size(@evidence.verification_facts || %{}) > 0} class="mb-4 space-y-1">
          <p class="text-xs font-bold uppercase tracking-[0.08em] text-secondary">
            Verification facts
          </p>
          <dl class="grid gap-1 text-sm sm:grid-cols-2">
            <%= for {key, value} <- @evidence.verification_facts do %>
              <div class="flex items-baseline gap-2">
                <dt class="mono text-xs text-secondary">{key}</dt>
                <dd class="mono text-xs text-base-content">{inspect_value(value)}</dd>
              </div>
            <% end %>
          </dl>
        </div>

        <%= case @reveal_state do %>
          <% :revealed -> %>
            <div class="space-y-1">
              <p class="text-xs font-bold uppercase tracking-[0.08em] text-secondary">
                Raw payload (read-only)
              </p>
              <pre
                data-testid="inbound-evidence-raw"
                class="mono max-h-96 overflow-auto rounded-box border border-base-300 bg-base-100 p-3 text-xs text-base-content"
              ><%= raw_payload_text(@evidence) %></pre>
            </div>

          <% :denied -> %>
            <p
              data-testid="inbound-evidence-denied"
              class="rounded-box border border-warning bg-warning/10 p-3 text-sm text-base-content"
            >
              Raw source not revealed: the reveal_raw capability is not granted for this operator.
            </p>

          <% _redacted -> %>
            <p
              data-testid="inbound-evidence-redacted"
              class="mono rounded-box border border-base-300 bg-base-100 p-3 text-xs text-secondary"
            >
              Raw source redacted. Revealing the raw provider payload requires the reveal_raw capability.
            </p>
        <% end %>
      <% end %>
    </article>
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

  defp inspect_value(value) when is_binary(value), do: value
  defp inspect_value(value), do: inspect(value)
end
