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

  @prefix "mailglass"
  @tenant_id "schema-isolation-immutability-tenant"

  # Inline wrapper migration that stands up the mailglass schema by calling
  # Mailglass.Migration.up/down directly — NO path-pinning execute of any kind.
  # Plan 134-01's maybe_create_schema/1 issues `CREATE SCHEMA IF NOT EXISTS
  # "mailglass"` as the first up action, and Plan 134-02's qualified DDL binds
  # the trigger/function to mailglass.* with no ambient path.
  defmodule PrefixedWrapperMigration do
    use Ecto.Migration

    @prefix "mailglass"

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
    # Override the schema to "mailglass" for this test so Config.schema/0
    # returns "mailglass". The rest of the suite pins :schema to "public".
    #
    # 143-MECHANISM.md § "The three-class inventory" names this file as a
    # Class B (config_schema_drift) candidate: it flips Config.schema()
    # per-test. Closed here via the restore-first `with_schema!/2` seam
    # (143-07) — the restore is registered before any statement below (the
    # schema drop/migrate) that can raise.
    with_schema!(@prefix)

    # Pre-clean only — we rely on the migration's OWN `CREATE SCHEMA IF NOT
    # EXISTS` (Plan 134-01 maybe_create_schema/1) to stand the schema up, rather
    # than a manual CREATE SCHEMA here. A DROP ... CASCADE gives a clean slate.
    #
    # NO explicit `:prefix` is passed to `Ecto.Migrator.up/4` below — still
    # correct for `up/4` specifically: at this point `mailglass` does not yet
    # exist (just dropped above), so Ecto's ambient-search_path-resolved
    # `schema_migrations` bookkeeping table lands in `public` (confirmed
    # live), not inside the schema this migration creates. An explicit
    # `prefix: "public"` here would raise `Ecto.MigrationError` (mismatch
    # against `PrefixedWrapperMigration`'s own `create table(prefix:
    # "mailglass")` DSL calls); `prefix: "mailglass"` was also tried and
    # ruled out (see the down-test's own comment for the full mechanism and
    # empirical trail — the down side of this same ambiguity is what
    # actually needed fixing, and now does not use `Ecto.Migrator.down/4` at
    # all).
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
      {:ok, _} = TestRepo.query("CREATE EXTENSION IF NOT EXISTS citext")

      # `with_schema!/2`'s own on_exit (registered before this one, so it runs
      # after — reverse on_exit order) restores `config :mailglass, :schema`
      # to the captured boot value. Nothing to do here for that key.

      # Under the CI schema-isolation axis (MAILGLASS_SCHEMA=mailglass) the suite
      # baseline schema IS `mailglass` (migrated at boot). This test's teardown
      # dropped it, so re-migrate the baseline before the next test file runs.
      # No-op on the default "public" suite.
      restore_suite_baseline_schema()
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

    test "migrating down against prefix mailglass succeeds and the schema is gone", %{
      version: version
    } do
      # Roll back the wrapper migration recorded in setup — its down/0 calls
      # Mailglass.Migration.down(prefix: "mailglass"), which drops all tables +
      # the schema (DROP SCHEMA ... RESTRICT once empty). No search_path pin.
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
      # independently via the public API. Leaving `:prefix` unset (this
      # test's original code) lets the DSL's own explicit `prefix:
      # "mailglass"` through unchallenged, but leaves bookkeeping resolution
      # to the ambient `search_path` (`"mailglass, public"` on this axis,
      # per test_helper.exs). At `up/4` time `mailglass` does not exist yet
      # (this test's own pre-clean drops it), so the unqualified `CREATE
      # TABLE IF NOT EXISTS schema_migrations` targets the next schema that
      # DOES exist — `public` — and the version row lands there. At `down/4`
      # time `mailglass` now DOES exist (created by `up/4`'s own
      # `maybe_create_schema/1`), and Postgres's `IF NOT EXISTS` existence
      # check is scoped to the RESOLVED TARGET schema only, not search-path-
      # wide — so `ensure_schema_migrations_table!/3` silently creates a
      # SECOND, empty `schema_migrations` table INSIDE `mailglass` (now first
      # in the ambient search path), and the version lookup against it comes
      # back empty. `Ecto.Migrator.down/4` concludes `:already_down` and
      # never even attempts the DROP — confirmed live via a throwaway probe:
      # `down/4` returned `{:ok, :already_down, []}` and `mailglass` was
      # still there afterward, no schema-level error, no deadlock, just a
      # silently-skipped rollback. (A DIFFERENT prior attempt that forced
      # `prefix: "mailglass"` explicitly on both calls hit a genuine ~20-60s
      # Postgres lock deadlock instead, per WINDOWS id 7 — a different
      # symptom of the same underlying conflation, not evidence this path is
      # unfixable.)
      #
      # `Ecto.Migration.Runner.run/8` (the function `Ecto.Migrator.up/4`/
      # `down/4` themselves call internally, `@moduledoc false` but not
      # `defp`) drives the migration module's `up/0`/`down/0` directly
      # without EVER touching `SchemaMigration`/`lock_for_migrations` — no
      # bookkeeping table is created, queried, or orphaned inside `mailglass`
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

  # When the suite runs under MAILGLASS_SCHEMA=mailglass, re-migrate the suite
  # baseline schema this test's teardown dropped (idempotent — the migration
  # entrypoint issues CREATE SCHEMA IF NOT EXISTS + creates tables under
  # Config.schema/0). No-op on the default "public" suite.
  defp restore_suite_baseline_schema do
    if System.get_env("MAILGLASS_SCHEMA") in [nil, "", "public"] do
      :ok
    else
      # The boot migration files (versions 1..N) are still recorded as applied in
      # public.schema_migrations even though this teardown dropped the mailglass
      # schema. `:up all` would therefore be a no-op and NOT re-create the schema.
      # Clear the boot-migration version rows so the migrator re-applies them.
      {:ok, _} = TestRepo.query("DELETE FROM public.schema_migrations WHERE version < 100")

      migrations_path = Path.join(:code.priv_dir(:mailglass), "repo/migrations")

      {:ok, _, _} =
        SandboxOwnership.reloading_flat_migrations(fn ->
          Ecto.Migrator.with_repo(TestRepo, fn repo ->
            Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
          end)
        end)

      # A restore that cannot be OBSERVED to have worked must not report
      # success (D-31). `Ecto.Migrator.run/4` returning `{:ok, _, _}` proves
      # only that the migrator ran — not that the baseline relations came back
      # in the schema the rest of the suite will look in. Without this check a
      # failed restore is silent here and surfaces as a `42P01` cascade in
      # whichever unrelated `async: false` module happens to run next, which is
      # exactly the Class A misattribution this phase exists to end.
      case SandboxOwnership.baseline_tables_present?(TestRepo) do
        true ->
          :ok

        {false, missing} ->
          raise """
          #{inspect(__MODULE__)}: suite baseline restore did not complete. \
          Missing relation(s) in schema #{inspect(Mailglass.Config.schema())}: \
          #{Enum.join(missing, ", ")}. The next async: false module would have \
          failed with a 42P01 that had nothing to do with it — failing here \
          instead, at the module that actually broke the baseline.
          """

        {:cannot_verify, reason} ->
          raise """
          #{inspect(__MODULE__)}: could not verify the suite baseline restore \
          (#{inspect(reason)}). Refusing to report a restore that cannot be \
          observed — see D-31.
          """
      end
    end
  end
end
