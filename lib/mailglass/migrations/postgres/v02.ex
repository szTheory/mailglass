defmodule Mailglass.Migrations.Postgres.V02 do
  @moduledoc false
  use Ecto.Migration

  # Phase 4 Wave 0 (CONTEXT D-15). Two DDL actions:
  #
  #   1. Create `mailglass_webhook_events` — separate mutable table that
  #      owns raw provider payloads + per-webhook processing state. Keeps
  #      the append-only `mailglass_events` ledger pristine (SQLSTATE 45A01
  #      trigger unchanged) while giving GDPR erasure a targeted surface
  #      (`DELETE FROM mailglass_webhook_events WHERE raw_payload->>'to' = ?`).
  #
  #   2. Drop `mailglass_events.raw_payload` — the column is nullable
  #      (V01:77) and no shipped v0.1 writer populates it (verified in
  #      RESEARCH Runtime State Inventory). Raw provider evidence now lives
  #      in `mailglass_webhook_events.raw_payload`; the ledger holds the
  #      normalized projection only.
  #
  # Immutability-trigger safety: `mailglass_events_immutable_trigger` is
  # a BEFORE UPDATE OR DELETE trigger on a row — dropping a column via
  # ALTER TABLE is an operator/DDL action, not a row mutation, so the
  # trigger does not fire (Postgres design). Verified in RESEARCH §Pattern
  # 5.

  def up(opts \\ []) do
    prefix = opts[:prefix]

    create table(:mailglass_webhook_events, primary_key: false, prefix: prefix) do
      # UUIDv7 client-side via Mailglass.Schema (wrapper writers pass `:id` explicitly).
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      add(:provider, :text, null: false)
      add(:provider_event_id, :text, null: false)
      add(:event_type_raw, :text, null: false)
      # Nullable: populated by `normalize/2` — remains nil if the provider
      # string falls through to `:unknown` before Multi commit.
      add(:event_type_normalized, :text)
      # `:received | :processing | :succeeded | :failed | :dead`
      add(:status, :text, null: false)
      # JSONB at the DB level — Postgrex maps :map -> jsonb.
      # Mutable + prunable; PII lives here (per Retention Pruner, D-16).
      add(:raw_payload, :map, null: false)
      add(:received_at, :utc_datetime_usec, null: false)
      add(:processed_at, :utc_datetime_usec)
      timestamps(type: :utc_datetime_usec)
    end

    # Webhook-source idempotency: one row per (provider, provider_event_id).
    # Plan 06's `Mailglass.Webhook.Ingest` Multi inserts with
    # `on_conflict: :nothing, conflict_target: [:provider, :provider_event_id]`
    # — a replay is a no-op SELECT-by-index, not an INSERT.
    create(
      unique_index(:mailglass_webhook_events, [:provider, :provider_event_id],
        name: :mailglass_webhook_events_provider_event_id_idx,
        prefix: prefix
      )
    )

    # Partial index for admin DLQ/retry surfaces — most webhooks succeed
    # quickly, so a global index on `status` wastes space. Narrow the
    # index to the rows operators actually scan.
    create(
      index(:mailglass_webhook_events, [:tenant_id, :status],
        where: "status IN ('failed', 'dead')",
        name: :mailglass_webhook_events_tenant_status_idx,
        prefix: prefix
      )
    )

    # Drop the unused `mailglass_events.raw_payload` column. V01:77 declared
    # it nullable and no shipped v0.1 writer populates it (Phase 3 Projector
    # writes to `mailglass_deliveries`; Events.append_multi sets
    # `normalized_payload` + `metadata` only). Raw evidence now lives in
    # `mailglass_webhook_events.raw_payload`.
    alter table(:mailglass_events, prefix: prefix) do
      remove(:raw_payload)
    end
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]

    # Reverse in opposite order: restore the dropped column first (so a
    # partial rollback leaves the ledger queryable), then drop the new
    # table + its indexes. `drop(table/2)` cascades to its indexes.
    alter table(:mailglass_events, prefix: prefix) do
      add(:raw_payload, :map)
    end

    drop(
      index(:mailglass_webhook_events, [:tenant_id, :status],
        name: :mailglass_webhook_events_tenant_status_idx,
        prefix: prefix
      )
    )

    drop(
      unique_index(:mailglass_webhook_events, [:provider, :provider_event_id],
        name: :mailglass_webhook_events_provider_event_id_idx,
        prefix: prefix
      )
    )

    drop(table(:mailglass_webhook_events, prefix: prefix))
  end
end
