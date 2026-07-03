defmodule Mailglass.Migrations.Postgres.V01 do
  @moduledoc false
  use Ecto.Migration

  def up(opts \\ []) do
    prefix = opts[:prefix]

    # Gate every raw #{q}. interpolation below through the single
    # unquoted-identifier chokepoint (decision 132-01 / T-134-01). `inspect/1`
    # double-quotes an already-validated identifier.
    Mailglass.Identifier.validate!(prefix, :prefix)
    q = inspect(prefix)

    # citext extension FIRST — Pitfall 8: ordering matters; mailglass_suppressions.address
    # declares :citext below and Postgres resolves the type at CREATE TABLE time.
    # LEFT UNqualified on purpose (MIGR-05): citext installs into public so
    # case-insensitive resolution works with no search_path pin.
    execute("CREATE EXTENSION IF NOT EXISTS citext")

    # Table 1: mailglass_deliveries — mutable projection of latest event state per recipient/send.
    create table(:mailglass_deliveries, primary_key: false, prefix: prefix) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      add(:mailable, :text, null: false)
      add(:stream, :text, null: false)
      add(:recipient, :text, null: false)
      add(:recipient_domain, :text, null: false)
      add(:provider, :text)
      add(:provider_message_id, :text)
      add(:last_event_type, :text, null: false)
      add(:last_event_at, :utc_datetime_usec, null: false)
      add(:terminal, :boolean, null: false, default: false)
      add(:dispatched_at, :utc_datetime_usec)
      add(:delivered_at, :utc_datetime_usec)
      add(:bounced_at, :utc_datetime_usec)
      add(:complained_at, :utc_datetime_usec)
      add(:suppressed_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: %{})
      add(:lock_version, :integer, null: false, default: 1)
      timestamps(type: :utc_datetime_usec)
    end

    create(
      unique_index(:mailglass_deliveries, [:provider, :provider_message_id],
        where: "provider_message_id IS NOT NULL",
        name: :mailglass_deliveries_provider_msg_id_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_deliveries, [:tenant_id, "last_event_at DESC"],
        name: :mailglass_deliveries_tenant_recent_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_deliveries, [:tenant_id, :recipient],
        name: :mailglass_deliveries_tenant_recipient_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_deliveries, [:tenant_id, :stream, :terminal, "last_event_at DESC"],
        name: :mailglass_deliveries_tenant_stream_terminal_idx,
        prefix: prefix
      )
    )

    # Table 2: mailglass_events — append-only ledger. No :updated_at column.
    # delivery_id is a logical reference (UUID type) but NOT a foreign key
    # per ARCHITECTURE §4.3 — webhooks may arrive before the Delivery row exists
    # (orphan case; reconciled via 's Oban worker over the
    # needs_reconciliation flag).
    create table(:mailglass_events, primary_key: false, prefix: prefix) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      add(:delivery_id, :uuid)
      add(:type, :text, null: false)
      add(:occurred_at, :utc_datetime_usec, null: false)
      add(:idempotency_key, :text)
      add(:reject_reason, :text)
      add(:raw_payload, :map)
      add(:normalized_payload, :map, null: false, default: %{})
      add(:metadata, :map, null: false, default: %{})
      add(:trace_id, :text)
      add(:needs_reconciliation, :boolean, null: false, default: false)
      add(:inserted_at, :utc_datetime_usec, null: false, default: fragment("now()"))
    end

    # Pitfall 1: the `where:` clause here MUST match the Ecto
    # `conflict_target: {:unsafe_fragment, "(idempotency_key) WHERE idempotency_key IS NOT NULL"}`
    # that 's Events writer will use — character-for-character. Changing
    # this fragment here requires coordinated changes in the writer.
    create(
      unique_index(:mailglass_events, [:idempotency_key],
        where: "idempotency_key IS NOT NULL",
        name: :mailglass_events_idempotency_key_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_events, [:delivery_id, :occurred_at],
        where: "delivery_id IS NOT NULL",
        name: :mailglass_events_delivery_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_events, [:tenant_id, "inserted_at DESC"],
        name: :mailglass_events_tenant_recent_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_events, [:tenant_id, :inserted_at],
        where: "needs_reconciliation = true",
        name: :mailglass_events_needs_reconcile_idx,
        prefix: prefix
      )
    )

    # Trigger function FIRST, then trigger — ordering matters.
    # Pattern from accrue: plpgsql RAISE SQLSTATE '45A01' with a fixed
    # MESSAGE. Mailglass.Repo.transact/1 rescues %Postgrex.Error{pg_code: "45A01"}
    # and reraises Mailglass.EventLedgerImmutableError.
    # Schema-qualify the function (MIGR-03) so two installs in different schemas
    # of one DB never collide on the global function name. `SET search_path = ''`
    # is defense-in-depth (T-134-02 / CVE-2018-1058): the body references nothing
    # unqualified, so the empty path immunizes it against a caller's ambient path.
    execute(
      """
      CREATE OR REPLACE FUNCTION #{q}.mailglass_raise_immutability()
      RETURNS trigger
      LANGUAGE plpgsql
      SET search_path = ''
      AS $$
      BEGIN
        RAISE SQLSTATE '45A01'
          USING MESSAGE = 'mailglass_events is append-only; UPDATE and DELETE are forbidden';
      END;
      $$;
      """,
      "DROP FUNCTION IF EXISTS #{q}.mailglass_raise_immutability()"
    )

    execute(
      """
      CREATE TRIGGER mailglass_events_immutable_trigger
        BEFORE UPDATE OR DELETE ON #{q}.mailglass_events
        FOR EACH ROW EXECUTE FUNCTION #{q}.mailglass_raise_immutability();
      """,
      "DROP TRIGGER IF EXISTS mailglass_events_immutable_trigger ON #{q}.mailglass_events"
    )

    # Table 3: mailglass_suppressions — address- / domain- / stream-scoped blocks.
    # address is :citext (requires extension created above).
    create table(:mailglass_suppressions, primary_key: false, prefix: prefix) do
      add(:id, :uuid, primary_key: true)
      add(:tenant_id, :text, null: false)
      add(:address, :citext, null: false)
      add(:scope, :text, null: false)
      add(:stream, :text)
      add(:reason, :text, null: false)
      add(:source, :text, null: false)
      add(:expires_at, :utc_datetime_usec)
      add(:metadata, :map, null: false, default: %{})
      add(:inserted_at, :utc_datetime_usec, null: false, default: fragment("now()"))
    end

    # Structural CHECK per  — scope/stream coupling is a DB-level invariant
    # (belt-and-suspenders with the changeset's validate_scope_stream_coupling/1
    # in ). Either scope=:address_stream with stream NOT NULL, or
    # scope in (:address, :domain) with stream IS NULL.
    execute(
      """
      ALTER TABLE #{q}.mailglass_suppressions
        ADD CONSTRAINT mailglass_suppressions_stream_scope_check
        CHECK (
          (scope = 'address_stream' AND stream IS NOT NULL) OR
          (scope IN ('address', 'domain') AND stream IS NULL)
        )
      """,
      "ALTER TABLE #{q}.mailglass_suppressions DROP CONSTRAINT IF EXISTS mailglass_suppressions_stream_scope_check"
    )

    # UNIQUE with COALESCE(stream, '') normalizes NULL-vs-'' so
    # (:address, stream=nil) and (:address_stream, stream='bulk') are distinct.
    create(
      unique_index(
        :mailglass_suppressions,
        [:tenant_id, :address, :scope, "COALESCE(stream, '')"],
        name: :mailglass_suppressions_tenant_address_scope_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_suppressions, [:tenant_id, :address],
        name: :mailglass_suppressions_tenant_address_idx,
        prefix: prefix
      )
    )

    create(
      index(:mailglass_suppressions, [:expires_at],
        where: "expires_at IS NOT NULL",
        name: :mailglass_suppressions_expires_idx,
        prefix: prefix
      )
    )
  end

  def down(opts \\ []) do
    prefix = opts[:prefix]

    # Same identifier chokepoint as up/1 — Ecto does NOT prefix raw execute()
    # SQL, so the trigger/function drops must be hand-qualified with #{q}.
    Mailglass.Identifier.validate!(prefix, :prefix)
    q = inspect(prefix)

    # Reverse order: suppressions → trigger → function → events → deliveries → extension.
    drop(table(:mailglass_suppressions, prefix: prefix))

    execute("DROP TRIGGER IF EXISTS mailglass_events_immutable_trigger ON #{q}.mailglass_events")
    execute("DROP FUNCTION IF EXISTS #{q}.mailglass_raise_immutability()")

    drop(table(:mailglass_events, prefix: prefix))
    drop(table(:mailglass_deliveries, prefix: prefix))

    # citext stays UNqualified (installed into public). Dropping it on down is a
    # genuinely BEST-EFFORT teardown: with schema isolation a second install can
    # coexist in another schema (or the shared public baseline) whose tables
    # still depend on the extension. A bare `DROP EXTENSION IF EXISTS citext`
    # (no CASCADE) raises 2BP01 in that case, which would abort an otherwise
    # clean per-schema teardown. Guard the drop so it fires ONLY when no object
    # still depends on citext — never CASCADE (that would silently break the
    # surviving install's :citext columns). Redesigning the drop-on-down opt-in
    # is out of scope for this milestone (dossier §3.6).
    execute("""
    DO $$
    BEGIN
      IF NOT EXISTS (
        SELECT 1
        FROM pg_attribute a
        JOIN pg_class c ON c.oid = a.attrelid
        JOIN pg_type t ON t.oid = a.atttypid
        WHERE t.typname = 'citext'
          AND a.attnum > 0
          AND NOT a.attisdropped
          AND c.relkind IN ('r', 'p')
      ) THEN
        DROP EXTENSION IF EXISTS citext;
      END IF;
    END
    $$;
    """)
  end
end
