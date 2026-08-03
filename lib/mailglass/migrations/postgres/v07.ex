defmodule Mailglass.Migrations.Postgres.V07 do
  @moduledoc false
  use Ecto.Migration

  @states ~w(recoverable dispatching scrubbed expired terminal discarded abandoned uncertain legacy)
  @reason_classes ~w(
    dispatch_claimed accepted retention_expired provider_client_rejected pre_dispatch_failure
    payload_missing payload_corrupt payload_unsupported_version payload_expired payload_scrubbed
    job_discarded job_abandoned provider_acceptance_unknown legacy_queued
  )

  def up(opts \\ []) do
    prefix = opts[:prefix]
    quoted_prefix!(prefix)

    alter table(:mailglass_outbound_payloads, prefix: prefix) do
      add(:lifecycle_state, :text, null: false, default: "recoverable")
      add(:reason_class, :text)
      add(:claimed_at, :utc_datetime_usec)
      modify(:envelope, :map, null: true)
    end

    execute("""
    ALTER TABLE #{quoted_prefix!(prefix)}.mailglass_outbound_payloads
    ADD CONSTRAINT mailglass_outbound_payloads_lifecycle_state_check
    CHECK (lifecycle_state IN (#{quoted_values(@states)}))
    """)

    execute("""
    ALTER TABLE #{quoted_prefix!(prefix)}.mailglass_outbound_payloads
    ADD CONSTRAINT mailglass_outbound_payloads_reason_class_check
    CHECK (
      (lifecycle_state = 'recoverable' AND reason_class IS NULL) OR
      (lifecycle_state = 'dispatching' AND reason_class = 'dispatch_claimed') OR
      (lifecycle_state = 'scrubbed' AND reason_class = 'accepted') OR
      (lifecycle_state = 'terminal' AND reason_class IN ('provider_client_rejected', 'pre_dispatch_failure', 'payload_missing', 'payload_corrupt', 'payload_unsupported_version', 'payload_expired', 'payload_scrubbed')) OR
      (lifecycle_state = 'discarded' AND reason_class = 'job_discarded') OR
      (lifecycle_state = 'abandoned' AND reason_class = 'job_abandoned') OR
      (lifecycle_state = 'uncertain' AND reason_class = 'provider_acceptance_unknown') OR
      (lifecycle_state = 'legacy' AND reason_class = 'legacy_queued') OR
      (lifecycle_state = 'expired' AND reason_class IN (#{quoted_values(@reason_classes)}))
    )
    """)

    execute("""
    ALTER TABLE #{quoted_prefix!(prefix)}.mailglass_outbound_payloads
    ADD CONSTRAINT mailglass_outbound_payloads_claim_check
    CHECK ((lifecycle_state = 'dispatching') = (claimed_at IS NOT NULL))
    """)

    execute("""
    ALTER TABLE #{quoted_prefix!(prefix)}.mailglass_outbound_payloads
    ADD CONSTRAINT mailglass_outbound_payloads_content_check
    CHECK (
      (lifecycle_state IN ('recoverable', 'dispatching', 'terminal', 'discarded', 'abandoned', 'uncertain') AND envelope IS NOT NULL) OR
      (lifecycle_state IN ('scrubbed', 'expired') AND envelope IS NULL) OR
      lifecycle_state = 'legacy'
    )
    """)

    create_if_not_exists(
      index(:mailglass_outbound_payloads, [:lifecycle_state, :expires_at],
        name: :mailglass_outbound_payloads_state_expires_at_idx,
        where: "expires_at IS NOT NULL",
        prefix: prefix
      )
    )
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]
    quoted_prefix = quoted_prefix!(prefix)

    # This preflight is intentionally the first downgrade action. A V06 row
    # cannot retain claims, lifecycle reasons, or tombstones, so refuse before
    # touching an index, constraint, column, or envelope nullability.
    execute("""
    DO $$
    BEGIN
      IF EXISTS (
        SELECT 1
        FROM #{quoted_prefix}.mailglass_outbound_payloads
        WHERE lifecycle_state <> 'recoverable'
           OR reason_class IS NOT NULL
           OR claimed_at IS NOT NULL
           OR envelope IS NULL
      ) THEN
        RAISE EXCEPTION 'Mailglass V07 downgrade refused: payload lifecycle facts would be lost; settle or remove them before downgrading';
      END IF;
    END
    $$
    """)

    drop_if_exists(
      index(:mailglass_outbound_payloads, [:lifecycle_state, :expires_at],
        name: :mailglass_outbound_payloads_state_expires_at_idx,
        prefix: prefix
      )
    )

    execute(
      "ALTER TABLE #{quoted_prefix}.mailglass_outbound_payloads DROP CONSTRAINT mailglass_outbound_payloads_content_check"
    )

    execute(
      "ALTER TABLE #{quoted_prefix}.mailglass_outbound_payloads DROP CONSTRAINT mailglass_outbound_payloads_claim_check"
    )

    execute(
      "ALTER TABLE #{quoted_prefix}.mailglass_outbound_payloads DROP CONSTRAINT mailglass_outbound_payloads_reason_class_check"
    )

    execute(
      "ALTER TABLE #{quoted_prefix}.mailglass_outbound_payloads DROP CONSTRAINT mailglass_outbound_payloads_lifecycle_state_check"
    )

    alter table(:mailglass_outbound_payloads, prefix: prefix) do
      modify(:envelope, :map, null: false)
      remove(:claimed_at)
      remove(:reason_class)
      remove(:lifecycle_state)
    end
  end

  defp quoted_prefix!(prefix) do
    Mailglass.Identifier.validate!(prefix, :prefix)
    inspect(prefix)
  end

  defp quoted_values(values), do: Enum.map_join(values, ", ", &"'#{&1}'")
end
