defmodule MailglassInbound.Migrations.Postgres.V01 do
  @moduledoc false
  use Ecto.Migration

  def up(opts \\ []) do
    prefix = opts[:prefix]

    # Gate every raw interpolation below through the single unquoted-identifier
    # chokepoint (T-135-03). `inspect/1` double-quotes an already-validated
    # identifier. Inbound has no trigger/function/CHECK DDL that requires raw
    # #{prefix}. interpolation — only CREATE SCHEMA (runner-owned) and
    # this record_version COMMENT (runner-owned) use raw interpolation; V01 itself
    # uses only the Ecto DSL with `prefix:` keyword threading.
    Mailglass.Identifier.validate!(prefix, :prefix)

    # -------------------------------------------------------------------------
    # Table 1: mailglass_inbound_records
    # Final state after 7 historical migrations:
    #   - base columns (migration 1)
    #   - suppression_flagged NOT NULL DEFAULT false (migration 7, inline here)
    # -------------------------------------------------------------------------
    create table(:mailglass_inbound_records, primary_key: false, prefix: prefix) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      add(:provider, :text, null: false)
      add(:provider_message_id, :text)
      add(:message_id, :text)
      add(:envelope_recipient, :text)
      add(:from, {:array, :map}, null: false, default: [])
      add(:to, {:array, :map}, null: false, default: [])
      add(:cc, {:array, :map}, null: false, default: [])
      add(:bcc, {:array, :map}, null: false, default: [])
      add(:reply_to, {:array, :map}, null: false, default: [])
      add(:subject, :text)
      add(:headers, :map, null: false, default: %{})
      add(:sent_at, :utc_datetime_usec)
      add(:received_at, :utc_datetime_usec, null: false)
      add(:text_body, :text)
      add(:html_body, :text)
      add(:attachments, {:array, :map}, null: false, default: [])
      # migration 7: suppression flag — inline at final state
      add(:suppression_flagged, :boolean, null: false, default: false)

      timestamps(type: :utc_datetime_usec)
    end

    # Base indexes (migration 1)
    create(index(:mailglass_inbound_records, [:tenant_id], prefix: prefix))
    create(index(:mailglass_inbound_records, [:tenant_id, :provider], prefix: prefix))

    # Postmark idempotency partial unique index (migration 2)
    create(
      unique_index(
        :mailglass_inbound_records,
        [:tenant_id, :provider, :provider_message_id],
        where: "provider_message_id IS NOT NULL",
        name: :mailglass_inbound_records_postmark_idempotency_idx,
        prefix: prefix
      )
    )

    # -------------------------------------------------------------------------
    # Table 2: mailglass_inbound_evidence
    # Final state after 7 historical migrations:
    #   - base columns (migration 1)
    #   - raw_mime_fingerprint STORED generated column (migration 4, inline here)
    # -------------------------------------------------------------------------
    create table(:mailglass_inbound_evidence, primary_key: false, prefix: prefix) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      add(:provider, :text, null: false)

      # FK to mailglass_inbound_records — no :prefix on references():
      # the FK inherits the enclosing create table block prefix automatically.
      add(
        :inbound_record_id,
        references(:mailglass_inbound_records, type: :uuid, on_delete: :nothing),
        null: false
      )

      add(:raw_payload, :map, null: false, default: %{})
      add(:raw_headers, :map, null: false, default: %{})
      add(:raw_mime, :binary)
      add(:verification_facts, :map, null: false, default: %{})
      add(:parse_warnings, :map, null: false, default: %{})
      add(:attachment_blobs, :map, null: false, default: %{})
      # migration 4: raw_mime_fingerprint STORED generated column, inline at final
      # state. The expression references only same-row columns, so no raw
      # #{prefix}. DDL is needed here.
      add(:raw_mime_fingerprint, :text,
        generated: "ALWAYS AS (CASE WHEN raw_mime IS NULL THEN NULL ELSE md5(raw_mime) END) STORED"
      )

      timestamps(type: :utc_datetime_usec)
    end

    # Base indexes (migration 1)
    create(unique_index(:mailglass_inbound_evidence, [:inbound_record_id], prefix: prefix))
    create(index(:mailglass_inbound_evidence, [:tenant_id], prefix: prefix))

    # Provider fingerprint partial unique indexes (migrations 4, 5, 6)
    create(
      unique_index(
        :mailglass_inbound_evidence,
        [:tenant_id, :provider, :raw_mime_fingerprint],
        where: "provider = 'sendgrid' AND raw_mime_fingerprint IS NOT NULL",
        name: :mailglass_inbound_records_sendgrid_fingerprint_idx,
        prefix: prefix
      )
    )

    create(
      unique_index(
        :mailglass_inbound_evidence,
        [:tenant_id, :provider, :raw_mime_fingerprint],
        where: "provider = 'mailgun' AND raw_mime_fingerprint IS NOT NULL",
        name: :mailglass_inbound_records_mailgun_fingerprint_idx,
        prefix: prefix
      )
    )

    create(
      unique_index(
        :mailglass_inbound_evidence,
        [:tenant_id, :provider, :raw_mime_fingerprint],
        where: "provider = 'ses' AND raw_mime_fingerprint IS NOT NULL",
        name: :mailglass_inbound_records_ses_fingerprint_idx,
        prefix: prefix
      )
    )

    # -------------------------------------------------------------------------
    # Table 3: mailglass_inbound_replay_runs
    # Final state after 7 historical migrations:
    #   - base columns (migration 1) — replay_id and mailbox are NULLABLE (migration 3)
    #   - source :text NOT NULL DEFAULT 'replay' (migration 3, inline here)
    # Skip migration 3's UPDATE backfill and DROP NOT NULL execute() entirely —
    # these are forward-only reconciliations meaningless against an empty table.
    # -------------------------------------------------------------------------
    create table(:mailglass_inbound_replay_runs, primary_key: false, prefix: prefix) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      # migration 3: replay_id and mailbox are NULLABLE at final state
      add(:replay_id, :text)
      add(:mailbox, :text)
      # migration 3: source NOT NULL DEFAULT 'replay' declared inline
      add(:source, :text, null: false, default: "replay")
      add(:outcome, :text)
      add(:outcome_reason, :text)
      add(:failure, :map, null: false, default: %{})
      add(:executed_at, :utc_datetime_usec, null: false)
      add(:metadata, :map, null: false, default: %{})

      # FKs — no :prefix on references(): inherits block prefix
      add(
        :inbound_record_id,
        references(:mailglass_inbound_records, type: :uuid, on_delete: :nothing),
        null: false
      )

      add(
        :inbound_evidence_id,
        references(:mailglass_inbound_evidence, type: :uuid, on_delete: :nothing),
        null: false
      )

      timestamps(type: :utc_datetime_usec)
    end

    # Indexes (migration 1)
    create(unique_index(:mailglass_inbound_replay_runs, [:tenant_id, :replay_id], prefix: prefix))
    create(index(:mailglass_inbound_replay_runs, [:tenant_id, :inbound_record_id], prefix: prefix))

    create(
      index(:mailglass_inbound_replay_runs, [:tenant_id, :inbound_evidence_id], prefix: prefix)
    )
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]

    Mailglass.Identifier.validate!(prefix, :prefix)

    # Drop in reverse FK order: replay_runs → evidence → records
    drop(table(:mailglass_inbound_replay_runs, prefix: prefix))
    drop(table(:mailglass_inbound_evidence, prefix: prefix))
    drop(table(:mailglass_inbound_records, prefix: prefix))
  end
end
