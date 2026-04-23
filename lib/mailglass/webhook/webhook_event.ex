defmodule Mailglass.Webhook.WebhookEvent do
  @moduledoc """
  Ecto schema for the `mailglass_webhook_events` table (V02 migration,
  Plan 04-01). Mutable + prunable — UNLIKE `mailglass_events` which is
  append-only via the SQLSTATE 45A01 trigger (CONTEXT D-15 split).

  Stores raw webhook payloads from Postmark + SendGrid for:

    * **Idempotency:** UNIQUE `(provider, provider_event_id)` defends
      against replay (D-15 + PITFALLS MAIL-03). Plan 04-06's
      `Mailglass.Webhook.Ingest.ingest_multi/3` inserts with
      `on_conflict: :nothing, conflict_target: [:provider, :provider_event_id]`
      — a replay is a no-op SELECT-by-index, not an INSERT.
    * **Audit:** full raw payload available for support / debugging.
    * **GDPR erasure:** targeted `DELETE FROM mailglass_webhook_events
      WHERE raw_payload->>'to' = ?` without touching the append-only
      ledger (D-15).

  The `:raw_payload` field is marked `redact: true` so `Inspect` output
  (test failures, IEx) does NOT leak PII bytes. Mirrors accrue's
  `webhook_event.ex:48` convention.

  ## Status state machine

  `:received → :processing → :succeeded | :failed → :dead`. Plan 04-06
  inserts at `:processing` and flips to `:succeeded` at the end of the
  Multi; failures (outside Plan 04-06 scope) will surface the Plan 08
  DLQ.
  """

  use Mailglass.Schema

  import Ecto.Changeset

  alias Mailglass.Clock

  @valid_statuses [:received, :processing, :succeeded, :failed, :dead]

  schema "mailglass_webhook_events" do
    field(:tenant_id, :string)
    # 'postmark' | 'sendgrid' — stored as text in the V02 DDL.
    field(:provider, :string)
    field(:provider_event_id, :string)
    field(:event_type_raw, :string)
    # Nullable until `normalize/2` classifies the event.
    field(:event_type_normalized, :string)
    field(:status, Ecto.Enum, values: @valid_statuses)
    # `redact: true` — `Inspect` output never leaks raw provider bytes.
    field(:raw_payload, :map, redact: true)
    field(:received_at, :utc_datetime_usec)
    field(:processed_at, :utc_datetime_usec)

    timestamps(type: :utc_datetime_usec)
  end

  @required ~w[tenant_id provider provider_event_id event_type_raw status raw_payload received_at]a
  @cast @required ++ ~w[event_type_normalized processed_at]a

  @doc """
  Builds a changeset for inserting a webhook_event row at ingest time.

  Caller passes `:provider`, `:provider_event_id`, `:event_type_raw`,
  `:tenant_id`, `:raw_payload`. Other fields default sensibly:

    * `:status` defaults to `:processing` (Plan 04-06 flips to
      `:succeeded` after the Multi commits)
    * `:received_at` defaults to `Mailglass.Clock.utc_now/0`
  """
  @doc since: "0.1.0"
  @spec changeset(map()) :: Ecto.Changeset.t()
  def changeset(attrs) when is_map(attrs) do
    attrs_with_defaults =
      attrs
      |> Map.put_new(:status, :processing)
      |> Map.put_new(:received_at, Clock.utc_now())

    %__MODULE__{}
    |> cast(attrs_with_defaults, @cast)
    |> validate_required(@required)
  end

  @doc "Closed set of valid `:status` atoms. Cross-checked in api_stability.md."
  @doc since: "0.1.0"
  @spec __statuses__() :: [atom()]
  def __statuses__, do: @valid_statuses
end
