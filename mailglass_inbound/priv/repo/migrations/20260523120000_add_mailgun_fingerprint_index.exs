defmodule MailglassInbound.Migrations.AddMailgunFingerprintIndex do
  @moduledoc false
  use Ecto.Migration

  # DRIFT #3 (RESEARCH/PATTERNS): the `raw_mime_fingerprint` generated column
  # already exists from `20260506220000_add_sendgrid_fingerprint_and_replay_contract_fields`.
  # This migration adds ONLY the Mailgun-scoped partial unique index so the
  # MD5(raw) dedupe fallback (D-46-10) is enforced for Mailgun payloads that
  # carry no usable RFC Message-Id. It does NOT recreate the column, and it does
  # NOT add any Message-Id dedupe index — Mailgun rows WITH a Message-Id already
  # dedupe through the generic `mailglass_inbound_records_postmark_idempotency_idx`
  # (DRIFT #2 — its columns are provider-agnostic).

  def up do
    create unique_index(
             :mailglass_inbound_evidence,
             [:tenant_id, :provider, :raw_mime_fingerprint],
             where: "provider = 'mailgun' AND raw_mime_fingerprint IS NOT NULL",
             name: :mailglass_inbound_records_mailgun_fingerprint_idx
           )
  end

  def down do
    drop_if_exists index(:mailglass_inbound_evidence, [:tenant_id, :provider, :raw_mime_fingerprint],
                     name: :mailglass_inbound_records_mailgun_fingerprint_idx
                   )
  end
end
