defmodule Mailglass.V06MigrationTest do
  @moduledoc false
  # DDL and a session-scoped hostile search_path require an isolated, serial module.
  use ExUnit.Case, async: false

  import Mailglass.TestSupport.SandboxOwnership, only: [unsandboxed_module: 1]

  alias Mailglass.Migrations.Postgres
  alias Mailglass.TestRepo
  alias Mailglass.TestSupport.SandboxOwnership

  @moduletag phase_150_task: "t150_07_01"
  @prefix "mailglass_v06_lifecycle_test"
  @decoy_prefix "mailglass_v06_lifecycle_decoy"

  # Ecto.Migration DDL must run under a migration runner. This wrapper stops at
  # V05, letting the test invoke V06 directly under a hostile search_path.
  defmodule V05PrerequisitesMigration do
    use Ecto.Migration

    @prefix "mailglass_v06_lifecycle_test"

    def up do
      Enum.each(1..5, fn version ->
        module = Module.concat([Mailglass.Migrations.Postgres, "V0#{version}"])
        apply(module, :up, [[prefix: @prefix]])
      end)
    end

    def down, do: :ok
  end

  defmodule V06UpMigration do
    use Ecto.Migration

    @prefix "mailglass_v06_lifecycle_test"

    def up, do: Postgres.V06.up(prefix: @prefix)
    def down, do: :ok
  end

  defmodule V06DownMigration do
    use Ecto.Migration

    @prefix "mailglass_v06_lifecycle_test"

    def up, do: Postgres.V06.down(prefix: @prefix)
    def down, do: :ok
  end

  setup :unsandboxed_module

  setup do
    prefix = SandboxOwnership.scratch_schema!(@prefix, caller: __MODULE__)
    decoy_prefix = SandboxOwnership.scratch_schema!(@decoy_prefix, caller: __MODULE__)
    version = System.system_time(:microsecond)

    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@decoy_prefix} CASCADE")
    {:ok, _} = TestRepo.query("CREATE SCHEMA #{@prefix}")
    {:ok, _} = TestRepo.query("CREATE SCHEMA #{@decoy_prefix}")

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.up(repo, version, V05PrerequisitesMigration, log: false)
      end)

    {:ok, _} = TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])

    on_exit(fn ->
      _ = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
      _ = TestRepo.query("DROP SCHEMA IF EXISTS #{@decoy_prefix} CASCADE")
      SandboxOwnership.assert_baseline_intact!(TestRepo, __MODULE__)
    end)

    {:ok, prefix: prefix, decoy_prefix: decoy_prefix}
  end

  test "V05 -> V06 -> down -> up is prefix-safe, lossless, and catalog-exact", %{
    prefix: prefix,
    decoy_prefix: decoy_prefix
  } do
    baseline_prefix = Mailglass.Config.schema()
    delivery_id = Ecto.UUID.generate()

    legacy_metadata = %{
      "adapter" => "Mailglass.Adapters.Fake",
      "assigns" => %{"nested" => ["ordered", 2, true]},
      "headers" => [["x-legacy", "present"]],
      "html_body" => "<p>legacy</p>",
      "provider_options" => %{"sandbox" => true},
      "recipient" => "legacy@example.test",
      "subject" => "legacy subject",
      "text_body" => "legacy text"
    }

    insert_legacy_delivery!(prefix, delivery_id, legacy_metadata)
    legacy_metadata_json = delivery_metadata_json!(prefix, delivery_id)
    create_decoy_objects!(decoy_prefix)

    # The configured schema is the running test baseline. Its identically named
    # V06 object proves that direct V06 execution must not follow ambient resolution.
    assert table_exists?(baseline_prefix, "mailglass_outbound_payloads")
    assert table_exists?(decoy_prefix, "mailglass_outbound_payloads")

    with_hostile_search_path!(decoy_prefix, fn -> run_v06_step!(V06UpMigration) end)

    assert table_exists?(prefix, "mailglass_outbound_payloads")
    refute foreign_table_exists?(decoy_prefix, "mailglass_outbound_payloads", prefix)
    assert payload_columns(prefix) == expected_payload_columns()

    assert payload_foreign_key(prefix) == [
             ["mailglass_outbound_payloads_delivery_id_fkey", prefix, "mailglass_deliveries", "c"]
           ]

    assert payload_indexes(prefix) == expected_payload_indexes()
    assert payload_count(prefix) == 0
    assert delivery_metadata_json!(prefix, delivery_id) == legacy_metadata_json

    original_signature = payload_signature(prefix)

    with_hostile_search_path!(decoy_prefix, fn -> run_v06_step!(V06DownMigration) end)

    refute table_exists?(prefix, "mailglass_outbound_payloads")
    assert table_exists?(prefix, "mailglass_deliveries")
    assert table_exists?(prefix, "mailglass_events")
    assert table_exists?(prefix, "mailglass_suppressions")
    assert index_exists?(prefix, "mailglass_deliveries_idempotency_key_unique_idx")
    assert table_exists?(baseline_prefix, "mailglass_outbound_payloads")
    assert table_exists?(decoy_prefix, "mailglass_outbound_payloads")
    assert index_exists?(decoy_prefix, "mailglass_outbound_payloads_delivery_id_idx")

    with_hostile_search_path!(decoy_prefix, fn -> run_v06_step!(V06UpMigration) end)

    assert payload_signature(prefix) == original_signature
    assert payload_count(prefix) == 0
    assert delivery_metadata_json!(prefix, delivery_id) == legacy_metadata_json
  end

  defp insert_legacy_delivery!(prefix, delivery_id, metadata) do
    TestRepo.query!(
      """
      INSERT INTO #{prefix}.mailglass_deliveries
        (id, tenant_id, mailable, stream, recipient, recipient_domain,
         last_event_type, last_event_at, metadata, status, inserted_at, updated_at)
      VALUES ($1::text::uuid, 'tenant-v06', 'Mailglass.LegacyMailer', 'transactional',
              'legacy@example.test', 'example.test', 'queued', now(), $2::jsonb,
              'queued', now(), now())
      """,
      [delivery_id, metadata]
    )
  end

  defp run_v06_step!(migration) do
    version = System.system_time(:microsecond)

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.up(repo, version, migration, log: false)
      end)

    {:ok, _} = TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])

    :ok
  end

  defp with_hostile_search_path!(decoy_prefix, fun) when is_function(fun, 0) do
    SandboxOwnership.with_search_path!("#{decoy_prefix}, public", fun,
      repo: TestRepo,
      caller: __MODULE__
    )
  end

  defp create_decoy_objects!(prefix) do
    TestRepo.query!(
      "CREATE TABLE #{prefix}.mailglass_outbound_payloads (id uuid PRIMARY KEY, delivery_id uuid NOT NULL)"
    )

    TestRepo.query!(
      "CREATE UNIQUE INDEX mailglass_outbound_payloads_delivery_id_idx ON #{prefix}.mailglass_outbound_payloads (delivery_id)"
    )
  end

  defp delivery_metadata_json!(prefix, delivery_id) do
    %{rows: [[metadata]]} =
      TestRepo.query!(
        "SELECT metadata::text FROM #{prefix}.mailglass_deliveries WHERE id = $1::text::uuid",
        [delivery_id]
      )

    metadata
  end

  defp payload_count(prefix) do
    %{rows: [[count]]} =
      TestRepo.query!("SELECT count(*) FROM #{prefix}.mailglass_outbound_payloads")

    count
  end

  defp payload_signature(prefix),
    do: {payload_columns(prefix), payload_foreign_key(prefix), payload_indexes(prefix)}

  defp payload_columns(prefix) do
    %{rows: rows} =
      TestRepo.query!(
        """
        SELECT a.attname, pg_catalog.format_type(a.atttypid, a.atttypmod), a.attnotnull
        FROM pg_catalog.pg_attribute AS a
        JOIN pg_catalog.pg_class AS c ON c.oid = a.attrelid
        JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace
        WHERE n.nspname = $1 AND c.relname = 'mailglass_outbound_payloads'
          AND a.attnum > 0 AND NOT a.attisdropped
        ORDER BY a.attnum
        """,
        [prefix]
      )

    rows
  end

  defp expected_payload_columns do
    [
      ["id", "uuid", true],
      ["tenant_id", "text", true],
      ["delivery_id", "uuid", true],
      ["envelope_version", "integer", true],
      ["envelope_digest", "text", true],
      ["envelope", "jsonb", true],
      ["scrubbed_at", "timestamp without time zone", false],
      ["expires_at", "timestamp without time zone", false],
      ["inserted_at", "timestamp without time zone", true],
      ["updated_at", "timestamp without time zone", true]
    ]
  end

  defp payload_foreign_key(prefix) do
    %{rows: rows} =
      TestRepo.query!(
        """
        SELECT con.conname, target_namespace.nspname, target.relname, con.confdeltype::text
        FROM pg_catalog.pg_constraint AS con
        JOIN pg_catalog.pg_class AS source ON source.oid = con.conrelid
        JOIN pg_catalog.pg_namespace AS source_namespace ON source_namespace.oid = source.relnamespace
        JOIN pg_catalog.pg_class AS target ON target.oid = con.confrelid
        JOIN pg_catalog.pg_namespace AS target_namespace ON target_namespace.oid = target.relnamespace
        WHERE source_namespace.nspname = $1 AND source.relname = 'mailglass_outbound_payloads'
          AND con.contype = 'f'
        """,
        [prefix]
      )

    rows
  end

  defp payload_indexes(prefix) do
    %{rows: rows} =
      TestRepo.query!(
        """
        SELECT idx.relname, pg_catalog.pg_get_expr(index_data.indpred, index_data.indrelid)
        FROM pg_catalog.pg_index AS index_data
        JOIN pg_catalog.pg_class AS table_data ON table_data.oid = index_data.indrelid
        JOIN pg_catalog.pg_namespace AS namespace_data ON namespace_data.oid = table_data.relnamespace
        JOIN pg_catalog.pg_class AS idx ON idx.oid = index_data.indexrelid
        WHERE namespace_data.nspname = $1 AND table_data.relname = 'mailglass_outbound_payloads'
          AND idx.relname IN ('mailglass_outbound_payloads_delivery_id_idx',
                              'mailglass_outbound_payloads_tenant_delivery_idx',
                              'mailglass_outbound_payloads_expires_at_idx')
        ORDER BY idx.relname
        """,
        [prefix]
      )

    rows
  end

  defp expected_payload_indexes do
    [
      ["mailglass_outbound_payloads_delivery_id_idx", nil],
      ["mailglass_outbound_payloads_expires_at_idx", "(expires_at IS NOT NULL)"],
      ["mailglass_outbound_payloads_tenant_delivery_idx", nil]
    ]
  end

  defp table_exists?(prefix, table_name) do
    %{rows: rows} =
      TestRepo.query!(
        "SELECT 1 FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = $1 AND c.relname = $2 AND c.relkind = 'r'",
        [prefix, table_name]
      )

    rows != []
  end

  defp foreign_table_exists?(source_prefix, table_name, target_prefix) do
    %{rows: rows} =
      TestRepo.query!(
        """
        SELECT 1
        FROM pg_catalog.pg_class AS source
        JOIN pg_catalog.pg_namespace AS source_namespace ON source_namespace.oid = source.relnamespace
        JOIN pg_catalog.pg_constraint AS con ON con.conrelid = source.oid
        JOIN pg_catalog.pg_class AS target ON target.oid = con.confrelid
        JOIN pg_catalog.pg_namespace AS target_namespace ON target_namespace.oid = target.relnamespace
        WHERE source_namespace.nspname = $1 AND source.relname = $2 AND target_namespace.nspname = $3
        """,
        [source_prefix, table_name, target_prefix]
      )

    rows != []
  end

  defp index_exists?(prefix, index_name) do
    %{rows: rows} =
      TestRepo.query!(
        "SELECT 1 FROM pg_catalog.pg_class c JOIN pg_catalog.pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = $1 AND c.relname = $2 AND c.relkind = 'i'",
        [prefix, index_name]
      )

    rows != []
  end
end
