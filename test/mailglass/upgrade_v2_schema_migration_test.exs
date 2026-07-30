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

  @prefix "mailglass"
  @tenant_id "upgrade-v2-schema-migration-tenant"

  # The emitted move-migration bytes, evaluated as an anonymous module. Evaluating
  # the emitted body (rather than hand-copying it) proves the EMITTED bytes
  # execute — the emitter is the tested surface.
  @emitted_body Mix.Tasks.Mailglass.Upgrade.V2Schema.migration_body("UpgradeV2SchemaMigrationTest")

  # Two-step wrapper migration:
  #   up/0   → seed public (1.x state) then run the emitted move up/0
  #   down/0 → run the emitted move down/0 then tear down public (1.x state)
  defmodule MoveWrapperMigration do
    use Ecto.Migration

    @emitted Mix.Tasks.Mailglass.Upgrade.V2Schema.migration_body("UpgradeV2SchemaMigrationTest")

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
      # Only reverse the MOVE (mailglass.* → public). The public 1.x seed is left
      # in place so the test can assert the four tables are back in public; final
      # teardown of the public objects happens in the test's on_exit.
      @emitted_mod.down()
    end
  end

  # Pool-wide :auto is acquired through the sanctioned door
  # (SandboxOwnership.unsandboxed_module/1). Its revert to :manual is
  # registered FIRST (this setup runs before the one below), so it runs LAST
  # — the file's own restore on_exit (registered second, below) still
  # executes while :auto is in effect.
  setup :unsandboxed_module

  setup do
    # The move migration hard-codes @schema "mailglass" in the emitted body; the
    # public seed is driven explicitly via prefix: "public". This file never
    # overrides `config :mailglass, :schema` itself (143-MECHANISM.md names it
    # only as a Class A — baseline_missing — candidate, not Class B), so there
    # is no override here for the `with_schema!/2` seam to close.

    # Clean slate: drop the target schema, and drop any leftover public mailglass
    # objects so the 1.x seed installs fresh.
    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
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

      {:ok, _} = TestRepo.query("CREATE EXTENSION IF NOT EXISTS citext")

      # Runs unconditionally — no presence guard decides whether to restore
      # (D-31 Class A). VERIFIED, not assumed: a restore that could not
      # complete raises naming the relations it could not find.
      restore_suite_baseline_schema()

      case SandboxOwnership.baseline_tables_present?(TestRepo) do
        true ->
          :ok

        {false, missing} ->
          raise """
          Mailglass.UpgradeV2SchemaMigrationTest: baseline restoration did not \
          complete — #{inspect(missing)} still absent from schema \
          #{inspect(Mailglass.Config.schema())} after restore_suite_baseline_schema/0 \
          ran. Rebuild a clean local baseline with `mix ecto.drop -r Mailglass.TestRepo \
          && mix ecto.create -r Mailglass.TestRepo`, or investigate why the migrator \
          considered these relations already applied.
          """

        {:cannot_verify, reason} ->
          raise """
          Mailglass.UpgradeV2SchemaMigrationTest: could not verify baseline restoration \
          — the verification probe itself failed (#{inspect(reason)}). A check that \
          cannot observe its subject must never report success.
          """
      end
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
        "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = $1 AND table_name LIKE 'mailglass_%'",
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
  # test_helper); under the CI schema-isolation axis they live in `mailglass`.
  # Either way our setup/teardown dropped them (the move relocated them into
  # `mailglass`, then on_exit dropped that schema CASCADE + cleaned public), so we
  # MUST re-migrate the baseline before the next test file boots — otherwise the
  # shared DB is poisoned (the citext probe hits an absent mailglass_suppressions
  # and exhausts). The boot-migration version rows still say "applied", so clear
  # them first to force the migrator to re-create the tables.
  defp restore_suite_baseline_schema do
    {:ok, _} = TestRepo.query("DELETE FROM public.schema_migrations WHERE version < 100")

    migrations_path = Path.join(:code.priv_dir(:mailglass), "repo/migrations")

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
      end)

    :ok
  end
end
