defmodule Mailglass.Webhook.Provider do
  @moduledoc false
  # SEALED at v0.1 — see docs/api_stability.md §Webhook (Phase 4 Wave 0
  # scaffolding, Wave 2 lock). Adopters cannot implement at v0.1: PROJECT
  # D-10 defers Mailgun/SES/Resend to v0.5 behind this same internal
  # behaviour. Two callbacks isolate crypto (verify!/3) from taxonomy
  # (normalize/2) per CONTEXT D-01.
  #
  # Contract is Conn-free (D-02) so it ports to v0.5 SES SQS polling +
  # inbound testing contexts without pulling `%Plug.Conn{}` into the
  # verify path. `Mailglass.Webhook.Plug` (Plan 04) does the
  # conn-to-tuple adaptation at a single choke point.

  @doc """
  Verify a webhook request's authenticity. Receives a 3-tuple of
  (raw_body, headers, config) — NOT a `%Plug.Conn{}` — per CONTEXT D-02
  so the contract is portable to v0.5 inbound + SES SQS polling contexts.

  Returns `:ok` on success. Raises `%Mailglass.SignatureError{}` with
  one of the seven closed atoms (per D-21) on failure. Raises
  `%Mailglass.ConfigError{type: :webhook_verification_key_missing}` on
  missing per-tenant secret.
  """
  @callback verify!(
              raw_body :: binary(),
              headers :: [{String.t(), String.t()}],
              config :: map()
            ) :: :ok

  @doc """
  Normalize a verified webhook body into a list of `%Mailglass.Events.Event{}`
  structs in the Anymail taxonomy verbatim (PROJECT D-14 + amendment).

  Pure — no DB, no PubSub, no telemetry. Exhaustive case per provider's
  documented event types; unmapped types fall through to `:unknown` with
  `Logger.warning` (NEVER silent `_ -> :hard_bounce`; per D-05).

  Provider identifiers (`"provider"`, `"provider_event_id"`, `"record_type"`,
  `"message_id"`) are stashed in `Event.metadata` with STRING keys per
  revision W9 — JSONB roundtrip safety; Plan 04's Ingest reads them from
  metadata to populate the `mailglass_webhook_events` row. The ledger's
  `%Event{}` struct itself has no `:provider` column (per V02 schema —
  provider identity lives on `mailglass_webhook_events`).
  """
  @callback normalize(
              raw_body :: binary(),
              headers :: [{String.t(), String.t()}]
            ) :: [Mailglass.Events.Event.t()]
end
