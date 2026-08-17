defmodule Mailglass.MigrationTest do
  # async: false — these tests inspect and mutate schema-level state.
  use ExUnit.Case, async: false

  @moduletag :phase_02_uat

  import Mailglass.TestSupport.SandboxOwnership, only: [unsandboxed_module: 1]

  alias Mailglass.Migration
  alias Mailglass.TestRepo
  alias Mailglass.TestSupport.SandboxOwnership

  @migrations_path Path.join(:code.priv_dir(:mailglass), "repo/migrations")

  # These tests don't use `Mailglass.DataCase` because they exercise the
  # Migration API itself (which issues DDL — CREATE TABLE / DROP TABLE /
  # COMMENT ON TABLE — that cannot be rolled back by a Sandbox transactional
  # wrapper). The "down" test tears the schema down entirely.
  #
  # Pool-wide :auto is acquired through the sanctioned door
  # (SandboxOwnership.unsandboxed_module/1) — every process (including the
  # ephemeral one `Ecto.Migrator.with_repo/2` spawns) checks out on demand, no
  # owner is required. Its revert to :manual is registered FIRST (this setup
  # runs before the one below), so it runs LAST — the file's own conditional
  # restoration on_exit (registered second, below) still executes while :auto
  # is in effect.
  #
  # 143-MECHANISM.md § "The three-class inventory" narrows Class A
  # (baseline_missing) toward this file's siblings (`Mailglass.MigrationTest`
  # itself had ZERO failures in both local captures — Assumption A3 is
  # REFUTED for this file specifically). The restoration below is still made
  # unconditional and verified (143-07): a presence-guard that decides "the
  # baseline looks fine, skip the restore" is exactly the "cannot verify,
  # reports green" shape D-31 exists to kill, wherever it lives.
  setup :unsandboxed_module

  setup do
    on_exit(fn ->
      # Restore UNCONDITIONALLY — not gated on ground truth, not on the
      # recorded migration version. A guard here (either shape) can be wrong
      # in the same way: the teardown test drops tables without necessarily
      # clearing `schema_migrations`, so a version-based check reports
      # "already migrated" for a database that has no tables at all, and a
      # presence-based check can itself be wrong under conditions this module
      # cannot fully enumerate. Skipping the restore either way left every
      # later test in the run failing with
      # `relation "…mailglass_suppressions" does not exist`, in turn swallowed
      # by the citext probe's retry loop and reported as "citext probe
      # exhausted" — pointing diagnosis at the citext type instead of at this
      # teardown.
      _ = restore_suite_baseline_schema()

      # VERIFIED, not assumed: reuse the formatter's own probe rather than
      # re-implementing the check. A restore that could not complete raises
      # naming the relations it could not find — it never returns quietly.
      verify_baseline_restored!()
    end)

    :ok
  end

  describe "up/0" do
    test "creates mailglass_deliveries, mailglass_events, mailglass_suppressions" do
      # Migrations already ran in test_helper.exs — verify state exists.
      assert table_exists?("mailglass_deliveries")
      assert table_exists?("mailglass_events")
      assert table_exists?("mailglass_suppressions")
      assert column_exists?("mailglass_deliveries", "adapter_ref")
    end

    test "installs the mailglass_events_immutable_trigger on mailglass_events" do
      {:ok, %{rows: rows}} =
        TestRepo.query(
          """
          SELECT trigger_name FROM information_schema.triggers
          WHERE event_object_table = 'mailglass_events'
            AND event_object_schema = $1
            AND trigger_name = 'mailglass_events_immutable_trigger'
          """,
          [Mailglass.Config.schema()]
        )

      # The trigger is registered for BOTH UPDATE and DELETE, so
      # information_schema returns two rows (one per event action).
      assert rows != []
      assert Enum.all?(rows, fn [name] -> name == "mailglass_events_immutable_trigger" end)
    end

    test "seeds the pg_class comment version marker to the current version" do
      # Current version is bumped by each V-step (Phase 2 shipped V01 = 1;
      # Phase 4 Plan 01 ships V02 = 2; the dispatcher's @current_version
      # drives this assertion so it stays correct as new versions land).
      assert Migration.migrated_version(prefix: Mailglass.Config.schema(), repo: TestRepo) ==
               Mailglass.Migrations.Postgres.current_version()
    end

    test "current version exposes V06 through the dispatcher" do
      assert Mailglass.Migrations.Postgres.current_version() == 6
    end

    test "is idempotent — rerunning the migration is a no-op" do
      version_before = Migration.migrated_version(prefix: Mailglass.Config.schema(), repo: TestRepo)

      # Rerunning through Ecto.Migrator against the already-migrated DB is a
      # no-op because Ecto's schema_migrations tracking skips applied files.
      # Shared-mode sandbox lets the migrator subprocess reuse our connection.
      {:ok, _, _} =
        SandboxOwnership.reloading_flat_migrations(fn ->
          Ecto.Migrator.with_repo(TestRepo, fn repo ->
            Ecto.Migrator.run(repo, @migrations_path, :up, all: true, log: false)
          end)
        end)

      assert Migration.migrated_version(prefix: Mailglass.Config.schema(), repo: TestRepo) ==
               version_before
    end

    test "created all four mailglass_events indexes" do
      {:ok, %{rows: rows}} =
        TestRepo.query(
          """
          SELECT indexname FROM pg_indexes
          WHERE tablename = 'mailglass_events'
            AND schemaname = $1
          ORDER BY indexname
          """,
          [Mailglass.Config.schema()]
        )

      names = Enum.map(rows, &hd/1)

      # Four custom indexes (idempotency partial, delivery partial, tenant_recent,
      # needs_reconcile partial). The PK index is also present (pkey).
      assert "mailglass_events_idempotency_key_idx" in names
      assert "mailglass_events_delivery_idx" in names
      assert "mailglass_events_tenant_recent_idx" in names
      assert "mailglass_events_needs_reconcile_idx" in names
    end

    test "mailglass_suppressions has stream_scope_check CHECK constraint" do
      # Schema-qualify the regclass so it resolves under the active schema
      # (Config.schema/0), not whatever the ambient search_path happens to be.
      schema = Mailglass.Config.schema()

      {:ok, %{rows: rows}} =
        TestRepo.query(
          """
          SELECT conname FROM pg_constraint
          WHERE conrelid = ($1 || '.mailglass_suppressions')::regclass
            AND contype = 'c'
          """,
          [schema]
        )

      names = Enum.map(rows, &hd/1)
      assert "mailglass_suppressions_stream_scope_check" in names
    end

    test "citext extension is installed" do
      {:ok, %{rows: rows}} =
        TestRepo.query("SELECT extname FROM pg_extension WHERE extname = 'citext'")

      assert rows == [["citext"]]
    end
  end

  describe "down/0" do
    @describetag :migration_roundtrip
    # :public_only — this is a GENERIC rollback round-trip on the ambient schema.
    # It contributes ZERO schema-isolation coverage on the mailglass axis: the
    # non-public up/down lifecycle is proven independently by the
    # `describe "up/down against a non-public prefix (MIGR-01/02 regression)"`
    # sibling below (tagged :schema_isolation, DROP SCHEMA RESTRICT lifecycle at
    # lines ~317-353). On the mailglass axis the harness connection search_path
    # ("mailglass, public") + Sandbox :auto makes `Ecto.Migrator.run(:down,
    # all: true)` deadlock on `lock_for_migrations`; test_helper.exs excludes
    # :public_only on any non-public axis so this public-axis test runs only
    # where it validates something.
    @describetag :public_only
    test "drops all three tables + trigger + function + citext in reverse order" do
      # Roll the schema down through Ecto.Migrator (the same code path adopters
      # hit via `mix ecto.rollback`). :all with :down reverses every applied
      # migration — for V01 only, that drops everything back to the pre-initial
      # state (version 0). Shared-mode sandbox lets the migrator subprocess
      # reuse our owned connection.
      {:ok, _, _} =
        SandboxOwnership.reloading_flat_migrations(fn ->
          Ecto.Migrator.with_repo(TestRepo, fn repo ->
            Ecto.Migrator.run(repo, @migrations_path, :down, all: true, log: false)
          end)
        end)

      refute table_exists?("mailglass_deliveries")
      refute table_exists?("mailglass_events")
      refute table_exists?("mailglass_suppressions")
      refute column_exists?("mailglass_deliveries", "adapter_ref")

      # Trigger function should be dropped
      {:ok, %{rows: fn_rows}} =
        TestRepo.query("""
        SELECT proname FROM pg_proc WHERE proname = 'mailglass_raise_immutability'
        """)

      assert fn_rows == []

      # citext extension dropped too
      {:ok, %{rows: ext_rows}} =
        TestRepo.query("SELECT extname FROM pg_extension WHERE extname = 'citext'")

      assert ext_rows == []

      # Migrated version resets to 0 once the event table (whose pg_class
      # comment holds the version marker) is gone. Under the schema-isolation
      # axis the whole schema is dropped by the full teardown, so the version
      # query matches no rows and resolves to 0 either way.
      assert Migration.migrated_version(prefix: Mailglass.Config.schema(), repo: TestRepo) == 0

      # Reapply so subsequent tests / files in the same run have the schema
      # back. Uses Ecto.Migrator again — same path as test_helper.exs.
      {:ok, _, _} =
        SandboxOwnership.reloading_flat_migrations(fn ->
          Ecto.Migrator.with_repo(TestRepo, fn repo ->
            Ecto.Migrator.run(repo, @migrations_path, :up, all: true, log: false)
          end)
        end)

      # Version advances through every V-step the dispatcher currently
      # ships. Phase 4 Plan 01 bumped @current_version 1 → 2; future
      # V03+ will keep this assertion correct without another code edit.
      assert Migration.migrated_version(prefix: Mailglass.Config.schema(), repo: TestRepo) ==
               Mailglass.Migrations.Postgres.current_version()
    end
  end

  describe "up/down against a non-public prefix (MIGR-01/02 regression)" do
    @describetag :schema_isolation

    # A SCRATCH schema name unique to this describe block — NEVER the live schema
    # `Mailglass.Config.schema/0` resolves to, and never "public". Until the 143
    # gap-closure pass this was the literal "mailglass", which is harmless on the
    # default `public` axis (disjoint from the baseline) but IS the live baseline
    # schema under `MAILGLASS_SCHEMA=mailglass` — so the DROP SCHEMA ... CASCADE
    # statements in this block's setup, on_exit, and two of its tests dropped the
    # migration baseline out from under the rest of the run, surfacing as 42P01 in
    # unrelated victim modules hundreds of tests later. Naming precedent:
    # `mailglass_shipped_path_test` in
    # test/mailglass/shipped_migration_divergence_test.exs. The
    # `SandboxOwnership.scratch_schema!/2` call in this block's setup enforces
    # this structurally, so re-typing "mailglass" here raises at THIS module.
    #
    # MIGR-01/02 is unaffected by the rename: what this block proves is the
    # CREATE SCHEMA / DROP SCHEMA RESTRICT lifecycle against a NON-public prefix,
    # not against a prefix spelled "mailglass".
    @prefix "mailglass_migration_prefix_test"

    # Inline wrapper migration. `Mailglass.Migration.up` issues `execute()` DDL
    # that requires an active `Ecto.Migration.Runner` process, so it must be
    # driven through `Ecto.Migrator` (the same path adopters hit via
    # `mix ecto.migrate`), not called bare.
    #
    # NO ambient-path pin of any kind. These wrappers used to carry
    # `SET LOCAL search_path TO mailglass, public`, a DOCUMENTED CRUTCH for
    # v01's then-unqualified events-immutability trigger + function. Phase
    # 134-02 schema-qualified that raw DDL (`postgres/v01.ex:138,154` now emit
    # `#{q}.mailglass_raise_immutability` and `ON #{q}.mailglass_events`), so the
    # crutch is obsolete — and `schema_isolation_immutability_test.exs` exists
    # specifically to prove that, with an in-module self-check refusing any pin
    # in its own source.
    #
    # It is removed here because it was not merely obsolete, it was actively
    # harmful once this block moved to a scratch prefix: `SET LOCAL` persists for
    # the remainder of the transaction, and `Ecto.Migrator` inserts its
    # `schema_migrations` version row INSIDE that same transaction, AFTER the
    # migration body runs. The pin therefore redirected Ecto's own bookkeeping
    # INSERT to a search_path holding no `schema_migrations` table, raising
    # `42P01 (undefined_table) relation "schema_migrations" does not exist`.
    #
    # The DOWN-side raw-DDL round-trip (v01's `DROP EXTENSION citext` +
    # unqualified trigger/function drops) is intentionally NOT driven through the
    # migrator here: under the coexisting `public` suite, v01's shared-`citext`
    # drop raises 2BP01 (public.mailglass_suppressions still depends on citext).
    # Qualifying/guarding those `down/0` drops is Plan 134-02's job. To prove
    # 134-01's DROP SCHEMA RESTRICT lifecycle in isolation, the down-side test
    # drops the schema's tables directly, then exercises the dispatcher's
    # schema-drop on the now-empty schema.
    defmodule PrefixUpMigration do
      use Ecto.Migration

      # Must stay byte-identical to the enclosing describe block's @prefix.
      # Elixir module attributes do not cross a nested `defmodule` boundary, so
      # the literal is repeated here (the same shape the sibling prefixed-wrapper
      # migrations in this suite use).
      @scratch_schema "mailglass_migration_prefix_test"

      def up do
        Mailglass.Migration.up(prefix: @scratch_schema, repo: Mailglass.TestRepo)
      end

      # No-op down: the migrator requires a down/0, but 134-01's schema-teardown
      # proof runs the dispatcher's down directly (below), sidestepping v01's
      # 134-02-owned citext-drop collision.
      def down, do: :ok
    end

    defmodule PrefixNoCreateUpMigration do
      use Ecto.Migration

      # Must stay byte-identical to the enclosing describe block's @prefix — see
      # PrefixUpMigration above.
      @scratch_schema "mailglass_migration_prefix_test"

      def up do
        Mailglass.Migration.up(
          prefix: @scratch_schema,
          repo: Mailglass.TestRepo,
          create_schema: false
        )
      end

      def down, do: :ok
    end

    setup do
      # Assert @prefix is genuinely scratch before any DDL below touches it. This
      # block never calls `with_schema!/1`, so there is no ordering constraint
      # here beyond "before the DROP SCHEMA statements".
      _prefix = SandboxOwnership.scratch_schema!(@prefix, caller: __MODULE__)

      # Unique migration version per run so Ecto.Migrator's schema_migrations
      # tracking treats each run as fresh; on_exit cleans the schema + the
      # schema_migrations row so the test is re-runnable and does not pollute
      # subsequent files.
      version = System.unique_integer([:positive, :monotonic]) + 90_000_000_000_000

      on_exit(fn ->
        _ = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
        _ = TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])

        # Baseline safety net: v01's `down` (reachable through
        # `Mailglass.Migration.down/1`) runs an unqualified
        # `DROP EXTENSION IF EXISTS citext` that removes the shared `public`
        # extension the rest of the suite depends on (dossier: "citext stays in
        # public"). Guarding/qualifying that drop is Plan 134-02's job — until
        # then, re-create it here so subsequent test files (and the next
        # test_helper citext probe) see a clean baseline. This is scoped to this
        # describe block only.
        _ = TestRepo.query("CREATE EXTENSION IF NOT EXISTS citext SCHEMA public")

        # No baseline restoration is registered here. The DROP SCHEMA above
        # targets this block's own scratch schema, which no other module or axis
        # ever uses — before the 143 gap-closure pass it dropped the literal
        # "mailglass", the live baseline under MAILGLASS_SCHEMA=mailglass, and
        # then tried to re-migrate it from here.
        #
        # The file-level `setup`'s own `on_exit` (registered earlier, so it runs
        # AFTER this one) still restores unconditionally and verifies — it has to,
        # because the `:public_only` `down/0` describe genuinely tears the
        # configured schema down. This block only VERIFIES, so that a corruption
        # originating here is named here.
        SandboxOwnership.assert_baseline_intact!(TestRepo, __MODULE__)
      end)

      {:ok, version: version}
    end

    test "up creates the schema + its tables and re-up is a no-op", %{version: version} do
      # === up: CREATE SCHEMA (first action) + tables land under mailglass.* ===
      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.up(repo, version, PrefixUpMigration, log: false)
        end)

      assert schema_exists?(@prefix),
             "up/1 must CREATE SCHEMA #{@prefix} as its first action"

      assert table_exists_in_schema?(@prefix, "mailglass_events")
      assert table_exists_in_schema?(@prefix, "mailglass_deliveries")
      assert table_exists_in_schema?(@prefix, "mailglass_suppressions")

      # === re-up is a no-op (version-comment idempotency preserved) ===
      assert Migration.migrated_version(prefix: @prefix, repo: TestRepo) ==
               Mailglass.Migrations.Postgres.current_version()

      # Re-running the same version through the migrator is a no-op
      # (:already_up); the version comment stays at @current_version.
      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.up(repo, version, PrefixUpMigration, log: false)
        end)

      assert Migration.migrated_version(prefix: @prefix, repo: TestRepo) ==
               Mailglass.Migrations.Postgres.current_version()
    end

    test "DROP SCHEMA RESTRICT refuses a non-empty schema and succeeds once empty" do
      # Proves MIGR-02's down-side data-safety contract: `maybe_drop_schema/1`
      # emits `DROP SCHEMA IF EXISTS "<prefix>" RESTRICT` (NEVER CASCADE) — so a
      # schema that still holds objects (an adopter parked data there) fails
      # loudly rather than being silently nuked, and the drop succeeds only once
      # the schema is empty.
      #
      # This asserts the exact DDL the dispatcher issues at version 0, WITHOUT
      # driving `Mailglass.Migration.down/1` (which would also run v01's
      # unqualified `DROP EXTENSION citext` — a 134-02-owned raw-DDL concern that
      # would corrupt the shared `public.citext` baseline mid-suite).
      #
      # Clean slate: the block's setup already stood @prefix up via
      # PrefixUpMigration, so a bare CREATE SCHEMA would raise 42P06. Drop first.
      # Safe on every axis because @prefix is a scratch name (see its declaration
      # at the top of this describe block) — this DROP cannot reach the baseline.
      {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
      {:ok, _} = TestRepo.query("CREATE SCHEMA #{@prefix}")
      assert schema_exists?(@prefix)

      {:ok, _} = TestRepo.query("CREATE TABLE #{@prefix}.parked_object (id int)")

      # RESTRICT must refuse the drop while the schema is non-empty.
      assert {:error, %Postgrex.Error{postgres: %{code: :dependent_objects_still_exist}}} =
               TestRepo.query(~s(DROP SCHEMA IF EXISTS "#{@prefix}" RESTRICT))

      assert schema_exists?(@prefix),
             "RESTRICT must leave a non-empty schema in place (never CASCADE)"

      # Empty the schema, then the same RESTRICT drop succeeds and the schema is
      # gone — matching `maybe_drop_schema/1`'s post-teardown behavior.
      {:ok, _} = TestRepo.query("DROP TABLE #{@prefix}.parked_object")
      {:ok, _} = TestRepo.query(~s(DROP SCHEMA IF EXISTS "#{@prefix}" RESTRICT))

      refute schema_exists?(@prefix),
             "DROP SCHEMA RESTRICT must remove the now-empty #{@prefix} schema"
    end

    test "create_schema: false does not issue CREATE SCHEMA (locked-down-prod contract)", %{
      version: version
    } do
      # Pre-create the schema by hand (as a role WITH create would), then migrate
      # with create_schema: false to prove up/1 does NOT itself issue CREATE
      # SCHEMA — the tables still land because the schema already exists. A bare
      # create_schema: false against a MISSING schema would fail at CREATE TABLE,
      # which is the documented locked-down-prod contract (dossier §4.4).
      #
      # Clean slate first (the block's setup already stood @prefix up), then
      # hand-create so this test controls the pre-existing-schema precondition.
      # Safe on every axis because @prefix is a scratch name (see its declaration
      # at the top of this describe block) — this DROP cannot reach the baseline.
      {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
      {:ok, _} = TestRepo.query("CREATE SCHEMA #{@prefix}")

      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.up(repo, version, PrefixNoCreateUpMigration, log: false)
        end)

      assert table_exists_in_schema?(@prefix, "mailglass_events"),
             "tables must be created into the pre-existing schema even with create_schema: false"

      # The schema stays present (up with create_schema: false never creates it,
      # and there is no schema drop on this success path).
      assert schema_exists?(@prefix),
             "up/1 with create_schema: false must operate against the operator-owned schema"
    end
  end

  describe "catalog version classification" do
    alias Mailglass.Migrations.Postgres, as: MigrationRunner

    test "returns zero only when the core anchor relation is absent" do
      assert MigrationRunner.migrated_version(
               prefix: "catalog_fixture",
               query_result: {:ok, %{rows: []}}
             ) == 0
    end

    test "returns a complete numeric comment inside the supported range" do
      assert MigrationRunner.migrated_version(
               prefix: "catalog_fixture",
               query_result: {:ok, %{rows: [["3"]]}}
             ) == 3
    end

    for {name, result, reason} <- [
          {"a missing comment", {:ok, %{rows: [[nil]]}}, :missing_comment},
          {"a blank comment", {:ok, %{rows: [["  "]]}}, :invalid_comment},
          {"a non-numeric comment", {:ok, %{rows: [["3oops"]]}}, :invalid_comment},
          {"multiple catalog rows", {:ok, %{rows: [["1"], ["2"]]}}, :unexpected_result},
          {"an impossible version", {:ok, %{rows: [["0"]]}}, :out_of_range},
          {"a query error", {:error, :unavailable}, :query_failed}
        ] do
      test "raises a typed error for #{name}" do
        assert_raise Mailglass.MigrationVersionError, fn ->
          MigrationRunner.migrated_version(
            prefix: "catalog_fixture",
            query_result: unquote(Macro.escape(result))
          )
        end

        assert %Mailglass.MigrationVersionError{
                 reason: unquote(reason),
                 package: :mailglass,
                 prefix: "catalog_fixture"
               } =
                 catch_error(
                   MigrationRunner.migrated_version(
                     prefix: "catalog_fixture",
                     query_result: unquote(Macro.escape(result))
                   )
                 )
      end
    end
  end

  defp schema_exists?(prefix) do
    {:ok, %{rows: rows}} =
      TestRepo.query("SELECT 1 FROM pg_namespace WHERE nspname = $1", [prefix])

    rows != []
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

  # Schema-aware: resolves the active schema via Config.schema/0 so these tests
  # pass under BOTH the default "public" suite AND the CI schema-isolation axis
  # (MAILGLASS_SCHEMA=mailglass), where the migration entrypoint lands every
  # object in the `mailglass` schema.
  defp table_exists?(table_name), do: table_exists_in_schema?(Mailglass.Config.schema(), table_name)

  defp column_exists?(table_name, column_name) do
    {:ok, %{rows: rows}} =
      TestRepo.query(
        """
        SELECT 1 FROM information_schema.columns
        WHERE table_name = $1
          AND column_name = $2
          AND table_schema = $3
        """,
        [table_name, column_name, Mailglass.Config.schema()]
      )

    rows != []
  end

  # Re-migrate the suite baseline schema after a teardown dropped it. Under the
  # CI schema-isolation axis (MAILGLASS_SCHEMA=mailglass) the baseline IS
  # `mailglass`; a bare `:up all` would be a no-op because schema_migrations
  # still records the boot versions, so clear them first. No-op on the default
  # "public" suite.
  defp restore_suite_baseline_schema do
    maybe_clear_stale_baseline_versions()

    _ =
      SandboxOwnership.reloading_flat_migrations(fn ->
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.run(repo, @migrations_path, :up, all: true, log: false)
        end)
      end)

    :ok
  end

  # Only reached from a restore path, i.e. the baseline tables are known to be
  # absent. In that state the recorded baseline versions are stale on EVERY
  # axis, not just the schema-isolation one: leaving them behind makes
  # `Ecto.Migrator.run(:up)` a no-op and the schema is never re-created. The
  # previous `public`-axis carve-out is what made this reproduce specifically on
  # the `schema public` CI leg.
  defp maybe_clear_stale_baseline_versions do
    _ = TestRepo.query("DELETE FROM public.schema_migrations WHERE version < 100")
    :ok
  rescue
    _ -> :ok
  end

  # VERIFIED, not assumed (143-07 / D-31 Class A): delegates to
  # `SandboxOwnership.assert_baseline_intact!/2`, which raises naming THIS module
  # and the relations it could not find, and treats `:cannot_verify` as a failure
  # rather than a pass. Four modules used to hand-roll this same three-clause
  # `case` around `baseline_tables_present?/1`, each with its own wording; the
  # shared helper makes the "cannot verify" branch impossible to omit.
  defp verify_baseline_restored! do
    SandboxOwnership.assert_baseline_intact!(TestRepo, __MODULE__)
  end
end
