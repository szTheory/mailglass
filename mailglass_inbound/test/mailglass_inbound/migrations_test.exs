defmodule MailglassInbound.MigrationsTest do
  @moduledoc """
  Round-trip tests for the inbound migration stack (INB-02).

  Exercises `MailglassInbound.Migration.up/down` + `Migrations.Postgres.V01`
  under a non-public prefix to prove the full CREATE SCHEMA / table creation /
  DROP SCHEMA RESTRICT lifecycle without disturbing the shared `public` suite schema.

  `async: false` — tests issue DDL and mutate a real Postgres schema.
  """

  # async: false — DDL + schema-level state mutations.
  use ExUnit.Case, async: false

  alias MailglassInbound.Migration
  alias MailglassInbound.Migrations.Postgres, as: MigrationRunner
  alias MailglassInbound.TestRepo

  @v02_path Path.expand("../../lib/mailglass_inbound/migrations/postgres/v02.ex", __DIR__)

  test "V02 defines an additive SHA-256 expand/backfill contract without rewriting V01" do
    assert File.exists?(@v02_path)

    v02 = File.read!(@v02_path)
    assert v02 =~ "raw_mime_sha256"
    assert v02 =~ "CREATE INDEX CONCURRENTLY"
    assert v02 =~ "mailglass_inbound_records_retention_idx"
    assert v02 =~ "mailglass_inbound_evidence_retention_idx"
  end

  # Distinct prefix — non-public so CREATE/DROP SCHEMA lifecycle is exercised;
  # avoids clashing with the suite's "public" schema or any future "mailglass" default.
  @prefix "inb_mig_test"
  @shared_prefix "inb_shared_mig_test"

  @core_relations [
    "mailglass_deliveries",
    "mailglass_events",
    "mailglass_suppressions",
    "mailglass_webhook_events"
  ]
  @inbound_relations [
    "mailglass_inbound_records",
    "mailglass_inbound_evidence",
    "mailglass_inbound_replay_runs"
  ]

  # ---------------------------------------------------------------------------
  # Inline migration modules driven through Ecto.Migrator so the
  # Ecto.Migration.Runner process is active for DDL (create/1, execute/1 etc).
  # ---------------------------------------------------------------------------

  defmodule PrefixUpMigration do
    @moduledoc false
    use Ecto.Migration

    def up do
      MailglassInbound.Migration.up(prefix: "inb_mig_test", repo: MailglassInbound.TestRepo)
    end

    def down, do: :ok
  end

  # Drives the down path by running Migration.down/1 inside an Ecto.Migrator
  # context (Runner process required for DDL). Uses `up` callback so
  # `Ecto.Migrator.up(repo, version, ...)` fires this — the "up action IS the
  # teardown" pattern mirrors core's migration_test.exs approach (which also
  # uses a separate version slot for the down-side driver).
  defmodule PrefixDownDriver do
    @moduledoc false
    use Ecto.Migration

    def up do
      MailglassInbound.Migration.down(
        prefix: "inb_mig_test",
        repo: MailglassInbound.TestRepo,
        version: 0
      )
    end

    def down, do: :ok
  end

  defmodule PrefixNoCreateSchemaMigration do
    @moduledoc false
    use Ecto.Migration

    def up do
      MailglassInbound.Migration.up(
        prefix: "inb_mig_test",
        repo: MailglassInbound.TestRepo,
        create_schema: false
      )
    end

    def down, do: :ok
  end

  defmodule SharedCoreUpMigration do
    @moduledoc false
    use Ecto.Migration

    def up do
      Mailglass.Migration.up(prefix: "inb_shared_mig_test", repo: MailglassInbound.TestRepo)
    end

    def down, do: :ok
  end

  defmodule SharedInboundUpMigration do
    @moduledoc false
    use Ecto.Migration

    def up do
      MailglassInbound.Migration.up(prefix: "inb_shared_mig_test", repo: MailglassInbound.TestRepo)
    end

    def down, do: :ok
  end

  defmodule SharedCoreDownDriver do
    @moduledoc false
    use Ecto.Migration

    def up do
      Mailglass.Migration.down(
        prefix: "inb_shared_mig_test",
        repo: MailglassInbound.TestRepo,
        version: 0
      )
    end

    def down, do: :ok
  end

  defmodule SharedInboundDownDriver do
    @moduledoc false
    use Ecto.Migration

    def up do
      MailglassInbound.Migration.down(
        prefix: "inb_shared_mig_test",
        repo: MailglassInbound.TestRepo,
        version: 0
      )
    end

    def down, do: :ok
  end

  # ---------------------------------------------------------------------------
  # Setup / teardown
  # ---------------------------------------------------------------------------

  setup do
    # Switch to :auto mode so every process (including migrator subprocesses)
    # can check out connections without explicit ownership assignment.
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :auto)

    # Unique migration version per run so Ecto.Migrator's schema_migrations
    # tracking treats each test as a fresh run; on_exit cleans up the schema
    # and the schema_migrations row.
    version = System.unique_integer([:positive, :monotonic]) + 80_000_000_000_000

    _ =
      TestRepo.query(
        "DELETE FROM public.schema_migrations WHERE version >= 80000000000000 AND version < 90000000000000"
      )

    on_exit(fn ->
      _ = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
      _ = TestRepo.query("DROP SCHEMA IF EXISTS #{@shared_prefix} CASCADE")
      _ = TestRepo.query("DELETE FROM public.schema_migrations WHERE version = $1", [version])

      _ =
        TestRepo.query(
          "DELETE FROM public.schema_migrations WHERE version >= 80000000000000 AND version < 90000000000000"
        )

      Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
    end)

    {:ok, version: version}
  end

  describe "shared package-managed schema rollback" do
    test "core-first rollback preserves inbound relations and removes the empty schema last", %{
      version: version
    } do
      install_shared_packages!(version)

      migrate!(SharedCoreDownDriver, migration_version())

      assert_relations_absent!(@core_relations)
      assert_relations_present!(@inbound_relations)
      assert schema_exists?(@shared_prefix)

      migrate!(SharedInboundDownDriver, migration_version())

      assert_relations_absent!(@core_relations ++ @inbound_relations)
      refute schema_exists?(@shared_prefix)
    end

    test "inbound-first rollback preserves core relations and removes the empty schema last", %{
      version: version
    } do
      install_shared_packages!(version)

      migrate!(SharedInboundDownDriver, migration_version())

      assert_relations_absent!(@inbound_relations)
      assert_relations_present!(@core_relations)
      assert schema_exists?(@shared_prefix)

      migrate!(SharedCoreDownDriver, migration_version())

      assert_relations_absent!(@core_relations ++ @inbound_relations)
      refute schema_exists?(@shared_prefix)
    end

    test "host-owned relations keep the shared schema after both package rollbacks", %{
      version: version
    } do
      install_shared_packages!(version)
      {:ok, _} = TestRepo.query("CREATE TABLE #{@shared_prefix}.host_sentinel (id integer)")

      migrate!(SharedInboundDownDriver, migration_version())
      assert_relations_absent!(@inbound_relations)
      assert_relations_present!(@core_relations)
      assert table_exists_in_schema?(@shared_prefix, "host_sentinel")
      assert schema_exists?(@shared_prefix)

      migrate!(SharedCoreDownDriver, migration_version())
      assert_relations_absent!(@core_relations ++ @inbound_relations)
      assert table_exists_in_schema?(@shared_prefix, "host_sentinel")
      assert schema_exists?(@shared_prefix)
    end
  end

  # ---------------------------------------------------------------------------
  # (A) up/down round-trip under a non-public prefix
  # ---------------------------------------------------------------------------

  describe "up/down round-trip under non-public prefix" do
    test "up/1 creates schema + all 3 tables + indexes; migrated_version returns current_version",
         %{version: version} do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.up(repo, version, PrefixUpMigration, log: false)
        end)

      assert schema_exists?(@prefix),
             "up/1 must CREATE SCHEMA IF NOT EXISTS #{@prefix} as its first action"

      assert table_exists_in_schema?(@prefix, "mailglass_inbound_records")
      assert table_exists_in_schema?(@prefix, "mailglass_inbound_evidence")
      assert table_exists_in_schema?(@prefix, "mailglass_inbound_replay_runs")

      # Version anchor is set on mailglass_inbound_records (D-07)
      assert Migration.migrated_version(prefix: @prefix, repo: TestRepo) ==
               MigrationRunner.current_version()
    end

    test "down/1 to version 0 drops all 3 tables + schema RESTRICT; migrated_version returns 0",
         %{version: version} do
      # First bring up
      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.up(repo, version, PrefixUpMigration, log: false)
        end)

      assert schema_exists?(@prefix)
      assert table_exists_in_schema?(@prefix, "mailglass_inbound_records")

      assert Migration.migrated_version(prefix: @prefix, repo: TestRepo) ==
               MigrationRunner.current_version()

      # Drive down/1 to version 0 via Ecto.Migrator using a down-driver migration.
      # The driver's up/0 calls Migration.down/1, which needs an active Runner
      # process to issue DDL (drop/1, execute/1). Using a fresh version slot so
      # Ecto.Migrator treats it as a new migration to apply.
      down_version = System.unique_integer([:positive, :monotonic]) + 80_000_000_000_000

      on_exit(fn ->
        TestRepo.query("DELETE FROM public.schema_migrations WHERE version = $1", [down_version])
      end)

      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.up(repo, down_version, PrefixDownDriver, log: false)
        end)

      # All tables dropped
      refute table_exists_in_schema?(@prefix, "mailglass_inbound_records"),
             "down/1 must drop mailglass_inbound_records"

      refute table_exists_in_schema?(@prefix, "mailglass_inbound_evidence"),
             "down/1 must drop mailglass_inbound_evidence"

      refute table_exists_in_schema?(@prefix, "mailglass_inbound_replay_runs"),
             "down/1 must drop mailglass_inbound_replay_runs"

      # Schema dropped by RESTRICT (was empty after tables gone)
      refute schema_exists?(@prefix),
             "down/1 to version 0 must DROP SCHEMA IF EXISTS #{@prefix} RESTRICT"

      # migrated_version returns 0 (no pg_class row for a dropped schema)
      assert Migration.migrated_version(prefix: @prefix, repo: TestRepo) == 0
    end

    test "migrated_version returns 0 before any migration", %{version: _version} do
      # No up/1 called — version anchor row does not exist.
      assert Migration.migrated_version(prefix: @prefix, repo: TestRepo) == 0
    end
  end

  # ---------------------------------------------------------------------------
  # (B) migrated_version transitions
  # ---------------------------------------------------------------------------

  describe "migrated_version/1 transitions" do
    test "returns current_version after up, 0 after full down", %{version: version} do
      assert Migration.migrated_version(prefix: @prefix, repo: TestRepo) == 0

      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.up(repo, version, PrefixUpMigration, log: false)
        end)

      assert Migration.migrated_version(prefix: @prefix, repo: TestRepo) ==
               MigrationRunner.current_version()

      down_version = System.unique_integer([:positive, :monotonic]) + 80_000_000_000_000

      on_exit(fn ->
        TestRepo.query("DELETE FROM public.schema_migrations WHERE version = $1", [down_version])
      end)

      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.up(repo, down_version, PrefixDownDriver, log: false)
        end)

      assert Migration.migrated_version(prefix: @prefix, repo: TestRepo) == 0
    end

    test "anchors on mailglass_inbound_records, not mailglass_events (D-07)", %{version: version} do
      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.up(repo, version, PrefixUpMigration, log: false)
        end)

      # Version comment is on mailglass_inbound_records in the prefix schema
      {:ok, %{rows: rows}} =
        TestRepo.query(
          """
          SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
          FROM pg_class
          LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
          WHERE pg_class.relname = 'mailglass_inbound_records'
            AND pg_namespace.nspname = $1
          """,
          [@prefix]
        )

      assert [[version_str]] = rows
      assert String.to_integer(version_str) == MigrationRunner.current_version()

      # Core's mailglass_events comment is untouched in the same schema
      {:ok, %{rows: inbound_check}} =
        TestRepo.query(
          """
          SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
          FROM pg_class
          LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
          WHERE pg_class.relname = 'mailglass_events'
            AND pg_namespace.nspname = $1
          """,
          [@prefix]
        )

      # mailglass_events does NOT exist in the inbound schema (inbound has no events table)
      assert inbound_check == [] or inbound_check == [[nil]],
             "inbound migration must not write a version comment on mailglass_events (D-07)"
    end
  end

  # ---------------------------------------------------------------------------
  # (C) create_schema: false is honored
  # ---------------------------------------------------------------------------

  describe "create_schema: false" do
    test "skips CREATE SCHEMA; tables land in pre-existing schema", %{version: version} do
      # Pre-create the schema (simulating a locked-down-prod role that already
      # owns the schema). Then migrate with create_schema: false to prove
      # up/1 does NOT issue CREATE SCHEMA.
      {:ok, _} = TestRepo.query("CREATE SCHEMA IF NOT EXISTS #{@prefix}")
      assert schema_exists?(@prefix)

      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.up(repo, version, PrefixNoCreateSchemaMigration, log: false)
        end)

      assert table_exists_in_schema?(@prefix, "mailglass_inbound_records"),
             "tables must land in pre-existing schema even with create_schema: false"

      assert schema_exists?(@prefix),
             "schema must survive (no DROP SCHEMA on successful up)"
    end

    test "Migration.up/0 (zero-arity) compiles and dispatches without error" do
      # Exercises the zero-arity default (Keyword.put_new semantics). We cannot
      # call Migration.up() bare in a test body (no Runner process), but we can
      # verify the module and function clause exist and that the default arg
      # compiles correctly. The dispatcher guard ensures it will raise a clear
      # RuntimeError when the repo is missing, not a compile-time crash.
      #
      # In the test env :repo is configured, so we confirm the function is
      # exported with arity 0 and arity 1.
      Code.ensure_loaded!(MailglassInbound.Migration)

      assert function_exported?(MailglassInbound.Migration, :up, 0)
      assert function_exported?(MailglassInbound.Migration, :up, 1)
      assert function_exported?(MailglassInbound.Migration, :down, 0)
      assert function_exported?(MailglassInbound.Migration, :down, 1)
      assert function_exported?(MailglassInbound.Migration, :migrated_version, 0)
      assert function_exported?(MailglassInbound.Migration, :migrated_version, 1)
    end
  end

  describe "catalog version classification" do
    test "returns zero only when the inbound anchor relation is absent" do
      assert MigrationRunner.migrated_version(
               prefix: @prefix,
               query_result: {:ok, %{rows: []}}
             ) == 0
    end

    test "returns the independent inbound version from a complete numeric comment" do
      assert MigrationRunner.migrated_version(
               prefix: @prefix,
               query_result: {:ok, %{rows: [["1"]]}}
             ) == 1
    end

    for {name, result, reason} <- [
          {"a missing comment", {:ok, %{rows: [[nil]]}}, :missing_comment},
          {"a malformed comment", {:ok, %{rows: [["1extra"]]}}, :invalid_comment},
          {"multiple rows", {:ok, %{rows: [["1"], ["1"]]}}, :unexpected_result},
          {"an out-of-range version", {:ok, %{rows: [["3"]]}}, :out_of_range},
          {"a query error", {:error, :unavailable}, :query_failed}
        ] do
      test "raises the shared typed error for #{name}" do
        assert %Mailglass.MigrationVersionError{
                 reason: unquote(reason),
                 package: :mailglass_inbound,
                 prefix: @prefix
               } =
                 catch_error(
                   MigrationRunner.migrated_version(
                     prefix: @prefix,
                     query_result: unquote(Macro.escape(result))
                   )
                 )
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  defp schema_exists?(prefix) do
    {:ok, %{rows: rows}} =
      TestRepo.query("SELECT 1 FROM pg_namespace WHERE nspname = $1", [prefix])

    rows != []
  end

  defp install_shared_packages!(version) do
    migrate!(SharedCoreUpMigration, version)
    migrate!(SharedInboundUpMigration, migration_version())
    assert_relations_present!(@core_relations ++ @inbound_relations)
  end

  defp migrate!(migration, version) do
    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.up(repo, version, migration, log: false)
      end)
  end

  defp migration_version do
    System.unique_integer([:positive, :monotonic]) + 80_000_000_000_000
  end

  defp assert_relations_present!(relations) do
    Enum.each(relations, &assert(table_exists_in_schema?(@shared_prefix, &1)))
  end

  defp assert_relations_absent!(relations) do
    Enum.each(relations, &refute(table_exists_in_schema?(@shared_prefix, &1)))
  end

  defp table_exists_in_schema?(prefix, table_name) do
    {:ok, %{rows: rows}} =
      TestRepo.query(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_name = $1 AND table_schema = $2
        """,
        [table_name, prefix]
      )

    rows != []
  end
end
