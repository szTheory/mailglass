defmodule Mailglass.SchemaIsolationImmutabilityTest do
  # async: false — exercises DDL (CREATE SCHEMA / migration) that cannot run
  # inside the SQL Sandbox transactional wrapper. Uses Sandbox :auto mode for
  # setup; reverts to :manual in on_exit so DataCase tests stay isolated.
  #
  # LOAD-BEARING (MIGR-05): this test stands the mailglass schema up WITHOUT any
  # runtime-path pin — it relies entirely on Plan 134-02's schema-qualified v01
  # trigger + function DDL. The sibling schema_isolation_integration_test.exs
  # still uses a path-pinning CRUTCH; this module deliberately deletes that
  # crutch to prove the qualification is correct on its own. (The self-check
  # test below asserts the forbidden DDL clause appears nowhere in this source.)
  use ExUnit.Case, async: false

  @moduletag :schema_isolation

  import Mailglass.TestSupport.SandboxOwnership, only: [unsandboxed_module: 1, with_schema!: 1]

  alias Mailglass.TestRepo
  alias Mailglass.TestSupport.SandboxOwnership

  # A SCRATCH schema name unique to this module — NEVER the live schema
  # `Mailglass.Config.schema/0` resolves to, and never "public". Until the 143
  # gap-closure pass this was the literal "mailglass", which is harmless on the
  # default `public` axis (disjoint from the baseline) but IS the live baseline
  # schema under `MAILGLASS_SCHEMA=mailglass` — so the setup below CASCADE-
  # dropped the migration baseline out from under the rest of the run, surfacing
  # as 42P01 in unrelated victim modules hundreds of tests later. Naming
  # precedent: `mailglass_shipped_path_test` in
  # test/mailglass/shipped_migration_divergence_test.exs. The
  # `SandboxOwnership.scratch_schema!/2` call in `setup` enforces this
  # structurally, so re-typing "mailglass" here raises at THIS module.
  #
  # MIGR-05 is unaffected by the rename: the load-bearing property is that the
  # schema is a NON-public prefixed schema stood up with no ambient-path help,
  # not that it is spelled "mailglass".
  @prefix "mailglass_isolation_immutability_test"
  @tenant_id "schema-isolation-immutability-tenant"

  # Inline wrapper migration that stands the scratch schema up by calling
  # Mailglass.Migration.up/down directly — NO path-pinning execute of any kind.
  # Plan 134-01's maybe_create_schema/1 issues `CREATE SCHEMA IF NOT EXISTS
  # "<prefix>"` as the first up action, and Plan 134-02's qualified DDL binds
  # the trigger/function to <prefix>.* with no ambient path.
  defmodule PrefixedWrapperMigration do
    use Ecto.Migration

    @prefix "mailglass_isolation_immutability_test"

    def up do
      Mailglass.Migration.up(prefix: @prefix, repo: Mailglass.TestRepo)
    end

    def down do
      Mailglass.Migration.down(prefix: @prefix, repo: Mailglass.TestRepo)
    end
  end

  # Pool-wide :auto is acquired through the sanctioned door
  # (SandboxOwnership.unsandboxed_module/1). Its revert to :manual is
  # registered FIRST (this setup runs before the one below), so it runs LAST
  # — the file's own restore on_exit (registered second, below) still
  # executes while :auto is in effect.
  setup :unsandboxed_module

  setup do
    # FIRST statement of setup, before `with_schema!/1` below: assert @prefix is
    # genuinely scratch. Ordering is load-bearing — `with_schema!/1` makes
    # Config.schema/0 return @prefix, after which this guard could no longer
    # observe the schema the rest of the suite needs. See
    # `SandboxOwnership.scratch_schema!/2`'s own docs.
    prefix = SandboxOwnership.scratch_schema!(@prefix, caller: __MODULE__)

    # Registered BEFORE `with_schema!/1` so it runs AFTER that restore
    # (`on_exit` runs in reverse registration order) — the baseline must be
    # verified against the BOOT schema, not against this module's own override.
    # Read-only: it observes and names, it never restores (D-31). This module no
    # longer tears the baseline down at all; this check is what proves that
    # claim on every test rather than asserting it in a comment.
    on_exit(fn -> SandboxOwnership.assert_baseline_intact!(TestRepo, __MODULE__) end)

    # Override the schema to the scratch prefix for this test so Config.schema/0
    # returns it. The rest of the suite pins :schema to "public" (or to
    # "mailglass" on the schema-isolation axis).
    #
    # 143-MECHANISM.md § "The three-class inventory" names this file as a
    # Class B (config_schema_drift) candidate: it flips Config.schema()
    # per-test. Closed here via the restore-first `with_schema!/2` seam
    # (143-07) — the restore is registered before any statement below (the
    # schema drop/migrate) that can raise.
    with_schema!(prefix)

    # Pre-clean only — we rely on the migration's OWN `CREATE SCHEMA IF NOT
    # EXISTS` (Plan 134-01 maybe_create_schema/1) to stand the schema up, rather
    # than a manual CREATE SCHEMA here. A DROP ... CASCADE gives a clean slate,
    # and it is safe precisely because @prefix is a scratch name no other module
    # or axis uses.
    #
    # NO explicit `:prefix` is passed to `Ecto.Migrator.up/4` below. An explicit
    # `prefix: "public"` would raise `Ecto.MigrationError` (mismatch against
    # `PrefixedWrapperMigration`'s own `create table(prefix: @prefix)` DSL
    # calls), and an explicit `prefix: @prefix` would put Ecto's
    # `schema_migrations` bookkeeping table INSIDE the schema the down-side test
    # then drops (see the down-test's own comment for the full mechanism and
    # empirical trail). Leaving it unset resolves bookkeeping through the
    # ambient search_path to the live baseline schema, which this module never
    # drops — so the version row survives its own teardown and the unqualified
    # DELETE in `on_exit` below finds it.
    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")

    # Unique migration version per run — Ecto.Migrator records it in
    # schema_migrations and treats a re-used version as :already_up.
    version = System.unique_integer([:positive, :monotonic]) + 90_000_000_000_000

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.up(repo, version, PrefixedWrapperMigration, log: false)
      end)

    on_exit(fn ->
      {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")

      {:ok, _} =
        TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])

      # citext lives in public — re-assert it survived so downstream tests that
      # touch :citext columns are unaffected (belt-and-suspenders).
      {:ok, _} = TestRepo.query("CREATE EXTENSION IF NOT EXISTS citext SCHEMA public")

      # `with_schema!/2`'s own on_exit (registered before this one, so it runs
      # after — reverse on_exit order) restores `config :mailglass, :schema`
      # to the captured boot value. Nothing to do here for that key.
      #
      # No baseline restoration happens here, and none is needed: the DROP above
      # targets this module's own scratch schema, which no other module or axis
      # ever uses. The previous version of this file dropped the literal
      # "mailglass" — the live baseline under MAILGLASS_SCHEMA=mailglass — and
      # then tried to re-migrate it from here, behind an
      # `if System.get_env("MAILGLASS_SCHEMA") in [nil, "", "public"]` early
      # return. Not dropping the baseline in the first place removes the whole
      # failure mode instead of trying to undo it. The
      # `assert_baseline_intact!/2` registered at the top of `setup` verifies
      # that on every test.
    end)

    {:ok, version: version}
  end

  # Insert one event row directly under the prefixed schema so UPDATE/DELETE
  # have a target. Direct SQL avoids depending on the facade for the setup of a
  # pure DDL-invariant proof.
  defp insert_event!(id) do
    {:ok, _} =
      TestRepo.query(
        """
        INSERT INTO #{@prefix}.mailglass_events
          (id, tenant_id, type, occurred_at, normalized_payload, metadata, needs_reconciliation, inserted_at)
        VALUES ($1, $2, 'sent', now(), '{}'::jsonb, '{}'::jsonb, false, now())
        """,
        [Ecto.UUID.dump!(id), @tenant_id]
      )

    id
  end

  describe "MIGR-05 (load-bearing): 45A01 fires under mailglass schema with NO search_path pin" do
    test "UPDATE on mailglass.mailglass_events raises SQLSTATE 45A01" do
      id = Ecto.UUID.generate() |> insert_event!()

      assert {:error, %Postgrex.Error{postgres: postgres}} =
               TestRepo.query(
                 "UPDATE #{@prefix}.mailglass_events SET tenant_id = 'mutated' WHERE id = $1",
                 [Ecto.UUID.dump!(id)]
               )

      assert sqlstate(postgres) == "45A01",
             "UPDATE of the append-only ledger must raise SQLSTATE 45A01 (got #{inspect(postgres)})"
    end

    test "DELETE on mailglass.mailglass_events raises SQLSTATE 45A01" do
      id = Ecto.UUID.generate() |> insert_event!()

      assert {:error, %Postgrex.Error{postgres: postgres}} =
               TestRepo.query(
                 "DELETE FROM #{@prefix}.mailglass_events WHERE id = $1",
                 [Ecto.UUID.dump!(id)]
               )

      assert sqlstate(postgres) == "45A01",
             "DELETE of the append-only ledger must raise SQLSTATE 45A01 (got #{inspect(postgres)})"
    end

    test "immutability function lives in its own schema (no global-name collision across schemas)" do
      # MIGR-03 collision-avoidance guarantee: schema-qualifying the function
      # means two installs in different schemas of ONE database each get their
      # own `<schema>.mailglass_raise_immutability` and never fight over a global
      # name. The shared test DB is already migrated into `public` by the
      # baseline suite, so `public.mailglass_raise_immutability` legitimately
      # coexists — the proof is that the `mailglass` install got ITS OWN copy
      # (the CREATE succeeded despite public already owning the name), i.e. the
      # function is per-schema, not global.
      {:ok, %{rows: rows}} =
        TestRepo.query(
          """
          SELECT n.nspname
          FROM pg_proc p
          JOIN pg_namespace n ON n.oid = p.pronamespace
          WHERE p.proname = 'mailglass_raise_immutability'
          """,
          []
        )

      schemas = Enum.map(rows, fn [nsp] -> nsp end)

      assert @prefix in schemas,
             "mailglass_raise_immutability must exist in the #{@prefix} schema — its own copy (found #{inspect(schemas)})"

      # Each schema has its OWN function row — the mailglass install did not
      # collide with (or overwrite) any other schema's function.
      mailglass_rows = Enum.count(schemas, &(&1 == @prefix))

      assert mailglass_rows == 1,
             "exactly one mailglass_raise_immutability must exist in #{@prefix} (found #{mailglass_rows})"

      # Coexistence proof: if public also has one (baseline suite), the two are
      # distinct namespace rows — no global-name collision aborted the install.
      assert Enum.uniq(schemas) == schemas,
             "each schema's mailglass_raise_immutability must be a distinct per-schema object (found #{inspect(schemas)})"
    end

    test "mixed-case citext suppression address matches case-insensitively (citext stayed resolvable via public)" do
      id = Ecto.UUID.generate()

      {:ok, _} =
        TestRepo.query(
          """
          INSERT INTO #{@prefix}.mailglass_suppressions
            (id, tenant_id, address, scope, reason, source, metadata, inserted_at)
          VALUES ($1, $2, 'MixedCase@Example.COM', 'address', 'bounce', 'test', '{}'::jsonb, now())
          """,
          [Ecto.UUID.dump!(id), @tenant_id]
        )

      {:ok, %{rows: [[count]]}} =
        TestRepo.query(
          "SELECT COUNT(*) FROM #{@prefix}.mailglass_suppressions WHERE address = $1",
          ["mixedcase@example.com"]
        )

      assert count == 1,
             "a mixed-case :citext address must match a lower-case lookup — citext must resolve via public with no search_path pin (got #{count})"
    end

    test "migrating down against the scratch prefix succeeds and the schema is gone", %{
      version: version
    } do
      # Roll back the wrapper migration recorded in setup — its down/0 calls
      # Mailglass.Migration.down(prefix: @prefix), which drops all tables +
      # the schema (DROP SCHEMA ... RESTRICT once empty). No ambient-path pin.
      #
      # RESOLVED (orchestrator-directed gap closure, superseding the
      # deferred-items.md / WINDOWS id 7 write-up naming this unfixable):
      # this drives `Ecto.Migration.Runner.run/8` DIRECTLY instead of going
      # through `Ecto.Migrator.down/4`'s public API. Root cause, confirmed
      # empirically (probe script against a live connection, see
      # 143-07-SUMMARY.md's "Orchestrator-directed gap closure" section for
      # the full trail): `Ecto.Migrator.up/4`/`down/4` conflate two concerns
      # into one `:prefix` option — the DDL validation target (checked by
      # `Ecto.Migration.__prefix__/1` against the migration's own `create
      # table(prefix: ...)` calls) and the `schema_migrations` bookkeeping
      # table location (`Ecto.Migration.SchemaMigration.ensure_schema_
      # migrations_table!/3`, `versions/3`) — with NO way to set them
      # independently via the public API. Forcing `prefix: @prefix` on both
      # calls puts the bookkeeping table INSIDE the very schema this test's
      # `down` then drops — a self-referential drop that hit a genuine ~20-60s
      # Postgres lock deadlock (WINDOWS id 7). Leaving `:prefix` unset avoids
      # that, but hands bookkeeping resolution to the ambient search_path,
      # which made `Ecto.Migrator.down/4` resolve a DIFFERENT
      # `schema_migrations` table than `up/4` had written to and conclude
      # `:already_down` — confirmed live via a throwaway probe: `down/4`
      # returned `{:ok, :already_down, []}` and the schema was still there
      # afterward, no error, no deadlock, just a silently-skipped rollback.
      #
      # `Ecto.Migration.Runner.run/8` (the function `Ecto.Migrator.up/4`/
      # `down/4` themselves call internally, `@moduledoc false` but not
      # `defp`) drives the migration module's `up/0`/`down/0` directly
      # without EVER touching `SchemaMigration`/`lock_for_migrations` — no
      # bookkeeping table is created, queried, or orphaned inside @prefix
      # at all, so the self-referential-drop conflict has no way to arise.
      # This is the same class of deliberate, version-pinned internals
      # coupling `Mailglass.TestSupport.SandboxOwnership.probe/1` already
      # uses for `:sys.get_state/1` (see that module's moduledoc) — used here
      # only because the documented public API has no seam that keeps this
      # proof's own load-bearing property (a real prefixed schema, no
      # search_path pin) while also avoiding the conflation above.
      config = TestRepo.config()

      :ok =
        Ecto.Migration.Runner.run(
          TestRepo,
          config,
          version,
          PrefixedWrapperMigration,
          :forward,
          :down,
          :down,
          log: false
        )

      {:ok, %{rows: [[schema_count]]}} =
        TestRepo.query(
          "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = $1",
          [@prefix]
        )

      assert schema_count == 0,
             "Mailglass.Migration.down/1 must drop the #{@prefix} schema (RESTRICT, empty) — found #{schema_count}"
    end

    # LOAD-BEARING self-check: this proof is only valid if the test itself
    # contains no path-pinning crutch. Keep this assertion in-module so the
    # guarantee is self-contained (does not depend on a companion guard).
    #
    # The forbidden needle is assembled at runtime from fragments so the literal
    # phrase appears NOWHERE in this source except as a match target — otherwise
    # this very assertion would false-positive on its own message text.
    test "this test source pins no runtime path crutch" do
      source = File.read!(__ENV__.file)

      # Assemble "SET" + space + "search_path" without writing the joined phrase
      # as a source literal (which would false-positive on itself).
      needle = "SET" <> " " <> "search" <> "_path"

      refute source =~ needle,
             "MIGR-05 proof is invalid if the test pins the runtime path — the FACADE-04 crutch must be absent"
    end
  end

  # Postgrex surfaces a custom SQLSTATE like 45A01 as `code: :unknown` while
  # carrying the raw five-char SQLSTATE in `pg_code`. Read pg_code first; fall
  # back to a stringified named code for defensiveness.
  defp sqlstate(%{pg_code: pg_code}) when is_binary(pg_code), do: pg_code
  defp sqlstate(%{code: code}) when is_binary(code), do: code
  defp sqlstate(%{code: code}) when is_atom(code), do: Atom.to_string(code)
end
