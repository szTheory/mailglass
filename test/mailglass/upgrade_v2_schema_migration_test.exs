defmodule Mailglass.UpgradeV2SchemaMigrationTest do
  # async: false — exercises DDL (CREATE SCHEMA / ALTER TABLE … SET SCHEMA /
  # migration) that cannot run inside the SQL Sandbox transactional wrapper.
  # Uses Sandbox :auto mode for setup; reverts to :manual in on_exit so DataCase
  # tests stay isolated. Cloned from schema_isolation_immutability_test.exs.
  #
  # UPG-01/04: this test seeds the 1.x pre-move state (all four tables + trigger
  # in `public`, the shipped fresh-install path), then applies the EMITTED move
  # migration bytes and proves the moved DB is indistinguishable from a
  # fresh-installed one (45A01 fires under mailglass.* with NO search_path pin,
  # version comment + citext survive, down reverses to public).
  use ExUnit.Case, async: false

  @moduletag :schema_isolation

  import Mailglass.TestSupport.SandboxOwnership, only: [unsandboxed_module: 1]

  alias Mailglass.TestRepo
  alias Mailglass.TestSupport.SandboxOwnership

  # The MOVE TARGET is a SCRATCH schema name unique to this module — NEVER the
  # live schema `Mailglass.Config.schema/0` resolves to, and never "public".
  # Until the 143 gap-closure pass this was the literal "mailglass", which is
  # harmless on the default `public` axis but IS the live baseline schema under
  # `MAILGLASS_SCHEMA=mailglass` — so the setup below CASCADE-dropped the
  # migration baseline out from under the rest of the run, surfacing as 42P01 in
  # unrelated victim modules hundreds of tests later. The rename is possible
  # because `Mix.Tasks.Mailglass.Upgrade.V2Schema.migration_body/2` takes a
  # `:schema` option (default `"mailglass"`) that the emitted body interpolates
  # into its own `@schema` — see the `:schema` pass-through in
  # `MoveWrapperMigration` below, and the setup assertion that proves the
  # emitted bytes really carry this name rather than the default.
  #
  # Naming precedent: `mailglass_shipped_path_test` in
  # test/mailglass/shipped_migration_divergence_test.exs. The
  # `SandboxOwnership.scratch_schema!/2` call in `setup` enforces this
  # structurally, so re-typing "mailglass" here raises at THIS module.
  @prefix "mailglass_upgrade_v2_move_test"
  @tenant_id "upgrade-v2-schema-migration-tenant"

  # Two-step wrapper migration:
  #   up/0   → seed public (1.x state) then run the emitted move up/0
  #   down/0 → run the emitted move down/0 then tear down public (1.x state)
  defmodule MoveWrapperMigration do
    use Ecto.Migration

    # Must stay byte-identical to the outer module's @prefix. Elixir module
    # attributes do not cross a nested `defmodule` boundary, so the literal is
    # repeated here (the same shape the sibling prefixed-wrapper migrations in
    # this suite use). The outer module's `setup` asserts the emitted body
    # actually carries this name, so a drift between the two literals fails
    # loudly at this module instead of silently migrating into the wrong schema.
    @scratch_schema "mailglass_upgrade_v2_move_test"

    @emitted Mix.Tasks.Mailglass.Upgrade.V2Schema.migration_body(
               "UpgradeV2SchemaMigrationTest",
               schema: @scratch_schema
             )

    # Compile the emitted module once at load time; grab its module name so we can
    # invoke its up/0 and down/0 inside our runner (which carries the Ecto.Migration
    # runner process the emitted execute/1 calls need).
    [{emitted_mod, _bin}] = Code.compile_string(@emitted)
    @emitted_mod emitted_mod

    def up do
      # 1.x pre-move state: install all four tables + trigger/function into public.
      Mailglass.Migration.up(prefix: "public", repo: Mailglass.TestRepo)
      # Apply the EMITTED move migration up/0 (runs in this migration's runner).
      @emitted_mod.up()
    end

    def down do
      # Only reverse the MOVE (<scratch>.* → public). The public 1.x seed is left
      # in place so the test can assert the four tables are back in public; final
      # teardown of the public objects happens in the test's on_exit.
      @emitted_mod.down()
    end

    @doc false
    def __emitted_source__, do: @emitted
  end

  # Pool-wide :auto is acquired through the sanctioned door
  # (SandboxOwnership.unsandboxed_module/1). Its revert to :manual is
  # registered FIRST (this setup runs before the one below), so it runs LAST
  # — the file's own restore on_exit (registered second, below) still
  # executes while :auto is in effect.
  setup :unsandboxed_module

  setup do
    # The move migration bakes its target schema into the emitted body's own
    # `@schema`; the public seed is driven explicitly via prefix: "public". This
    # file never overrides `config :mailglass, :schema` itself (143-MECHANISM.md
    # names it only as a Class A — baseline_missing — candidate, not Class B),
    # so there is no override here for the `with_schema!/2` seam to close — and
    # therefore no `with_schema!/1`-ordering constraint on the guard below.
    prefix = SandboxOwnership.scratch_schema!(@prefix, caller: __MODULE__)

    # NON-VACUITY GUARD for the scratch rename: the guard above only sees the
    # OUTER module's @prefix. What actually decides where the move lands is the
    # `@schema` baked into the emitted migration bytes, via
    # `MoveWrapperMigration`'s own repeated literal. Assert the emitted source
    # really carries the scratch name, so a drift between the two literals (or a
    # future change that drops the `schema:` pass-through and falls back to the
    # `"mailglass"` default) fails HERE rather than silently CASCADE-dropping the
    # live baseline again.
    assert MoveWrapperMigration.__emitted_source__() =~ ~s(@schema "#{prefix}")

    # Clean slate: drop the move-target scratch schema, and drop any leftover
    # public mailglass objects so the 1.x seed installs fresh.
    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")

    # DELIBERATE, DOCUMENTED live-schema operation — the one place in this file
    # that is NOT covered by the scratch-schema guard, because it genuinely must
    # touch `public`. The emitted move migration's source side is hardcoded
    # (`ALTER TABLE public.mailglass_events SET SCHEMA …`, and three siblings):
    # the whole point of UPG-01/04 is to prove a 1.x install sitting in `public`
    # can be relocated, so this file MUST seed and then dismantle
    # `public.mailglass_*`. On the default axis `public` IS the live schema, so
    # this genuinely tears the suite baseline down — which is why, uniquely among
    # the five scratch-schema modules, this one keeps an unconditional
    # `restore_suite_baseline_schema/0` in `on_exit` plus a verification of it.
    # Under `MAILGLASS_SCHEMA=mailglass` the baseline lives in `mailglass`, which
    # this file now never touches, so the restore is a verified no-op there.
    clean_public_mailglass!()

    version = System.unique_integer([:positive, :monotonic]) + 90_000_000_000_000

    # `prefix: "public"` pins THIS wrapper migration's OWN schema_migrations
    # bookkeeping to a schema that always exists and is never dropped by this
    # (or any other) file — never the axis-configured schema, which this
    # setup itself just dropped (`DROP SCHEMA IF EXISTS #{@prefix} CASCADE`
    # above) and which `MoveWrapperMigration.up/0`'s own emitted body only
    # recreates AFTER Ecto.Migrator's bookkeeping-table creation would already
    # need it to exist. `version` is a huge, run-unique integer that never
    # collides with the flat baseline migrations' own 1..N versions, so this
    # is a self-contained ledger entry, safe regardless of where the flat
    # baseline's own bookkeeping happens to live for the current axis.
    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.up(repo, version, MoveWrapperMigration, log: false, prefix: "public")
      end)

    on_exit(fn ->
      {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
      clean_public_mailglass!()

      {:ok, _} =
        TestRepo.query("DELETE FROM public.schema_migrations WHERE version = $1", [version])

      {:ok, _} = TestRepo.query("CREATE EXTENSION IF NOT EXISTS citext SCHEMA public")

      # Runs unconditionally — no presence guard decides whether to restore
      # (D-31 Class A). Required here, unlike its four sibling scratch-schema
      # modules, because `clean_public_mailglass!/0` above genuinely dismantles
      # `public.mailglass_*` (see the long comment in `setup`), which IS the
      # suite baseline on the default axis.
      restore_suite_baseline_schema()

      # VERIFIED, not assumed: `Ecto.Migrator.run/4` returning `{:ok, _, _}`
      # proves only that the migrator ran, not that the baseline relations came
      # back in the schema the rest of the suite will look in. Raises naming this
      # module and the absent relations — never returns quietly, and a
      # `:cannot_verify` result raises just as loudly as a missing relation.
      SandboxOwnership.assert_baseline_intact!(TestRepo, __MODULE__)
    end)

    {:ok, version: version}
  end

  # Drop any public.mailglass_* tables + the public immutability function so each
  # run seeds a clean 1.x state (belt-and-suspenders across interrupted runs).
  defp clean_public_mailglass! do
    for t <-
          ~w(mailglass_events mailglass_deliveries mailglass_suppressions mailglass_webhook_events) do
      {:ok, _} = TestRepo.query("DROP TABLE IF EXISTS public.#{t} CASCADE")
    end

    {:ok, _} =
      TestRepo.query("DROP FUNCTION IF EXISTS public.mailglass_raise_immutability() CASCADE")

    :ok
  end

  defp table_count(schema) do
    {:ok, %{rows: [[count]]}} =
      TestRepo.query(
        """
        SELECT COUNT(*)
        FROM information_schema.tables
        WHERE table_schema = $1
          AND table_name IN (
            'mailglass_events',
            'mailglass_deliveries',
            'mailglass_suppressions',
            'mailglass_webhook_events'
          )
        """,
        [schema]
      )

    count
  end

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

  describe "UPG-04: generated move migration relocates the 1.x public install to mailglass.*" do
    test "all four tables live under mailglass.* and public has none" do
      assert table_count(@prefix) == 4,
             "all four mailglass tables must live under #{@prefix} after the move"

      assert table_count("public") == 0,
             "public must be empty of mailglass tables after the move"
    end

    test "UPDATE on mailglass.mailglass_events raises SQLSTATE 45A01 with no path pin" do
      id = Ecto.UUID.generate() |> insert_event!()

      assert {:error, %Postgrex.Error{postgres: postgres}} =
               TestRepo.query(
                 "UPDATE #{@prefix}.mailglass_events SET tenant_id = 'mutated' WHERE id = $1",
                 [Ecto.UUID.dump!(id)]
               )

      assert sqlstate(postgres) == "45A01",
             "UPDATE of the moved append-only ledger must raise SQLSTATE 45A01 (got #{inspect(postgres)})"
    end

    test "DELETE on mailglass.mailglass_events raises SQLSTATE 45A01 with no path pin" do
      id = Ecto.UUID.generate() |> insert_event!()

      assert {:error, %Postgrex.Error{postgres: postgres}} =
               TestRepo.query(
                 "DELETE FROM #{@prefix}.mailglass_events WHERE id = $1",
                 [Ecto.UUID.dump!(id)]
               )

      assert sqlstate(postgres) == "45A01",
             "DELETE of the moved append-only ledger must raise SQLSTATE 45A01 (got #{inspect(postgres)})"
    end

    test "the version-marker table comment survived the move (read dynamically, not hard-coded)" do
      expected = Integer.to_string(Mailglass.Migrations.Postgres.current_version())

      {:ok, %{rows: [[comment]]}} =
        TestRepo.query(
          "SELECT obj_description(('#{@prefix}.mailglass_events')::regclass, 'pg_class')",
          []
        )

      assert comment == expected,
             "version-marker comment must survive the move and equal current_version #{expected} (got #{inspect(comment)})"
    end

    test "mixed-case citext suppression address matches case-insensitively (citext stayed in public)" do
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
             "a mixed-case :citext address must match a lower-case lookup after the move (got #{count})"
    end

    test "down reverses the move: all four tables are back in public and the schema is gone", %{
      version: version
    } do
      # `prefix: "public"` must match the bookkeeping prefix the `up` call in
      # `setup` used above — otherwise Ecto.Migrator's own "is this version
      # applied?" check (an unqualified, ambient-current-schema-dependent
      # lookup without it) can miss the version the `up` call recorded,
      # silently no-op the whole `down` as `:already_down`, and leave the four
      # tables stranded under `mailglass` with no error raised.
      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.down(repo, version, MoveWrapperMigration, log: false, prefix: "public")
        end)

      assert table_count("public") == 4,
             "down must move all four tables back to public"

      {:ok, %{rows: [[schema_count]]}} =
        TestRepo.query(
          "SELECT COUNT(*) FROM information_schema.schemata WHERE schema_name = $1",
          [@prefix]
        )

      assert schema_count == 0,
             "down must leave the #{@prefix} schema gone (found #{schema_count})"
    end
  end

  defp sqlstate(%{pg_code: pg_code}) when is_binary(pg_code), do: pg_code
  defp sqlstate(%{code: code}) when is_binary(code), do: code
  defp sqlstate(%{code: code}) when is_atom(code), do: Atom.to_string(code)

  # Restore the suite baseline schema this test's teardown tore down. On the
  # default suite the baseline mailglass tables live in `public` (booted by
  # test_helper), and `clean_public_mailglass!/0` drops exactly those — so we
  # MUST re-migrate the baseline before the next test file boots, or the shared DB
  # is poisoned (the citext probe hits an absent mailglass_suppressions and
  # exhausts). Under the CI schema-isolation axis the baseline lives in
  # `mailglass`, which this file no longer touches at all, so this is a no-op
  # there — but it still RUNS unconditionally and is still VERIFIED, because an
  # axis guard that decides "this axis never needs it" is exactly the
  # "cannot verify, reports green" shape D-31 exists to kill. The boot-migration
  # version rows still say "applied", so clear them first to force the migrator
  # to re-create the tables.
  defp restore_suite_baseline_schema do
    {:ok, _} = TestRepo.query("DELETE FROM public.schema_migrations WHERE version < 100")

    migrations_path = Path.join(:code.priv_dir(:mailglass), "repo/migrations")

    {:ok, _, _} =
      SandboxOwnership.reloading_flat_migrations(fn ->
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
        end)
      end)

    :ok
  end
end
