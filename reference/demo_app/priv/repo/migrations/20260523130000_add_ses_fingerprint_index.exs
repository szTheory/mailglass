defmodule MailglassInbound.Migrations.AddSesFingerprintIndex do
  @moduledoc false
  use Ecto.Migration

  # WR-02: SES dedupes on `mail.messageId` (provider_message_id) when present,
  # but inline-content notifications and degraded payloads can omit it. Without a
  # fallback, such a message never dedupes and an SNS at-least-once redelivery
  # inserts a duplicate InboundRecord. This migration adds the SES-scoped partial
  # unique index on the (already-existing, generated) `raw_mime_fingerprint`
  # column so the MD5(raw_mime) dedupe fallback is enforced for SES payloads with
  # no usable provider_message_id — mirroring the Mailgun
  # (`20260523120000_add_mailgun_fingerprint_index`) and SendGrid
  # (`20260506220000`) fingerprint indexes. It does NOT recreate the column.

  def up do
    create(
      unique_index(
        :mailglass_inbound_evidence,
        [:tenant_id, :provider, :raw_mime_fingerprint],
        where: "provider = 'ses' AND raw_mime_fingerprint IS NOT NULL",
        name: :mailglass_inbound_records_ses_fingerprint_idx
      )
    )
  end

  def down do
    drop_if_exists(
      index(:mailglass_inbound_evidence, [:tenant_id, :provider, :raw_mime_fingerprint],
        name: :mailglass_inbound_records_ses_fingerprint_idx
      )
    )
  end
end
