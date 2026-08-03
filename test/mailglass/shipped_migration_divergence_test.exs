defmodule Mailglass.ShippedMigrationDivergenceTest do
  # async: false — exercises the SHIPPED public migration dispatcher
  # (`Mailglass.Migration.up/1`), which issues DDL (CREATE SCHEMA / CREATE TABLE
  # / CREATE INDEX) that cannot run inside the Sandbox transactional wrapper.
  use ExUnit.Case, async: false

  @moduletag :shipped_migration_divergence

  import Mailglass.TestSupport.SandboxOwnership, only: [unsandboxed_module: 1]

  alias Mailglass.TestRepo

  # A dedicated, non-`public` schema so the run is isolated from the
  # already-migrated public schema and every other test file. The shipped
  # dispatcher auto-creates this schema because PREFIX != "public"
  # (with_defaults/2 sets create_schema: prefix != "public").
  @prefix "mailglass_shipped_path_test"

  # Inline migration that mirrors the exact 8-line wrapper file
  # `mix mailglass.gen.migration` emits for adopters. Driving this through
  # `Ecto.Migrator` is the genuine adopter path — it stands up the
  # `Ecto.Migration` runner process that `Mailglass.Migration.up/1` requires
  # (the dispatcher issues `create`/`execute` DDL through that runner).
  #
  # NO ambient-path pin. This wrapper used to carry
  # `SET LOCAL search_path TO @prefix, public`, described as a crutch for v01's
  # then-unqualified `ON mailglass_events` trigger DDL. Phase 134-02 qualified
  # that DDL, and the pin turned out to be a latent, order-dependent bug of its
  # own: `SET LOCAL` persists for the rest of the transaction, and
  # `Ecto.Migrator` inserts its `schema_migrations` version row INSIDE that same
  # transaction AFTER the migration body — so the pin redirected Ecto's own
  # bookkeeping INSERT to a search_path holding no `schema_migrations` table.
  # Under `MAILGLASS_SCHEMA=mailglass` the boot bookkeeping table lives in
  # `mailglass`, not `public`, so this file failed 4/4 when run ALONE on that
  # axis and passed in a full suite only because some earlier module happened to
  # create `public.schema_migrations` first. Confirmed live before the fix
  # (`MAILGLASS_SCHEMA=mailglass mix test <this file>` → 4 tests, 4 failures,
  # all `42P01 … relation "schema_migrations" does not exist`).
  defmodule ShippedWrapperMigration do
    use Ecto.Migration

    @prefix "mailglass_shipped_path_test"

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
    # Clean slate — drop, then re-create the isolated test schema before
    # running the shipped dispatcher. (The dispatcher threads `prefix:` through
    # every V-step DDL but does not itself issue `CREATE SCHEMA`; the adopter's
    # schema pre-exists. We create it here so the prefix-threaded DDL has a home,
    # keeping the run isolated from `public` and other test files.)
    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
    {:ok, _} = TestRepo.query("CREATE SCHEMA #{@prefix}")

    # Run the SHIPPED adopter migration path (NOT the flat TestRepo
    # priv/repo/migrations files) through Ecto.Migrator, exactly as an
    # adopter's generated wrapper migration runs it, threading the isolated
    # prefix through every V-step.
    #
    # A UNIQUE migration version per setup is required: `Ecto.Migrator.up`
    # records the version in `schema_migrations` and treats a re-used version
    # as `:already_up` (skipping the run). Each test gets a fresh version so
    # the dispatcher actually executes; on_exit removes the row so no residue
    # leaks into the shared `schema_migrations` table.
    version = System.unique_integer([:positive, :monotonic]) + 90_000_000_000_000

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.up(repo, version, ShippedWrapperMigration, log: false)
      end)

    on_exit(fn ->
      {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")

      {:ok, _} =
        TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])
    end)

    :ok
  end

  describe "shipped Mailglass.Migration.up/1 → mailglass_deliveries DDL" do
    test "deliveries has the idempotency_key column" do
      assert deliveries_column_exists?("idempotency_key"),
             "shipped dispatcher must create mailglass_deliveries.idempotency_key " <>
               "(runtime delivery.ex:112 + Outbound upsert require it)"
    end

    test "deliveries has the status and last_error columns" do
      assert deliveries_column_exists?("status"),
             "shipped dispatcher must create mailglass_deliveries.status"

      assert deliveries_column_exists?("last_error"),
             "shipped dispatcher must create mailglass_deliveries.last_error"
    end

    test "deliveries has the partial unique idempotency index with the matching predicate" do
      {:ok, %{rows: rows}} =
        TestRepo.query(
          """
          SELECT indexdef FROM pg_indexes
          WHERE schemaname = $1
            AND tablename = 'mailglass_deliveries'
            AND indexname = 'mailglass_deliveries_idempotency_key_unique_idx'
          """,
          [@prefix]
        )

      assert rows != [],
             "shipped dispatcher must create " <>
               "mailglass_deliveries_idempotency_key_unique_idx"

      [[indexdef]] = rows

      assert indexdef =~ "idempotency_key IS NOT NULL",
             "the partial index predicate must be exactly `idempotency_key IS NOT NULL` " <>
               "to match Outbound's conflict_target fragment; got: #{indexdef}"
    end

    test "an idempotent upsert matching Outbound's conflict_target round-trips as a no-op" do
      key = "shipped-path-divergence-#{System.unique_integer([:positive])}"

      # First INSERT — supplies every non-null column v01 requires.
      assert {:ok, %{num_rows: 1}} = insert_delivery(key)

      # Second INSERT of the SAME idempotency_key, using the EXACT
      # ON CONFLICT fragment from outbound.ex:559 — must be a safe no-op.
      assert {:ok, _} = insert_delivery(key, on_conflict: true)

      # Exactly one row survives for this idempotency_key.
      {:ok, %{rows: [[count]]}} =
        TestRepo.query(
          "SELECT COUNT(*) FROM #{@prefix}.mailglass_deliveries WHERE idempotency_key = $1",
          [key]
        )

      assert count == 1,
             "idempotent upsert must round-trip as a safe no-op (row count stays 1)"
    end
  end

  test "the public generator emits only the complete stable facade wrapper" do
    root = Path.join(System.tmp_dir!(), "mailglass-generated-wrapper-#{System.unique_integer([:positive])}")
    on_exit(fn -> File.rm_rf(root) end)
    File.mkdir_p!(Path.join(root, "priv/repo/migrations"))

    File.write!(
      Path.join(root, "mix.exs"),
      "defmodule GeneratedHost.MixProject do\n  use Mix.Project\n  def project, do: [app: :generated_host]\nend\n"
    )

    File.cd!(root, fn ->
      Mix.Task.reenable("mailglass.gen.migration")
      assert :ok = Mix.Task.run("mailglass.gen.migration", [])

      [wrapper] = Path.wildcard("priv/repo/migrations/*_mailglass_install.exs")
      body = File.read!(wrapper)

      assert body =~ "def up, do: Mailglass.Migration.up()"
      assert body =~ "def down, do: Mailglass.Migration.down()"
      refute body =~ "def change"
      refute body =~ "create table"
    end)
  end

  defp deliveries_column_exists?(column_name) do
    {:ok, %{rows: rows}} =
      TestRepo.query(
        """
        SELECT 1 FROM information_schema.columns
        WHERE table_schema = $1
          AND table_name = 'mailglass_deliveries'
          AND column_name = $2
        """,
        [@prefix, column_name]
      )

    rows != []
  end

  # Builds a raw INSERT into PREFIX.mailglass_deliveries so the assertion
  # exercises the SHIPPED DDL, not the Ecto schema. Supplies all NOT NULL
  # columns v01 declares (id, tenant_id, mailable, stream, recipient,
  # recipient_domain, last_event_type, last_event_at) plus idempotency_key.
  defp insert_delivery(key, opts \\ []) do
    conflict =
      if opts[:on_conflict] do
        # Exact fragment from outbound.ex:559 / :582-583.
        "ON CONFLICT (idempotency_key) WHERE idempotency_key IS NOT NULL DO NOTHING"
      else
        ""
      end

    sql = """
    INSERT INTO #{@prefix}.mailglass_deliveries
      (id, tenant_id, mailable, stream, recipient, recipient_domain,
       last_event_type, last_event_at, idempotency_key, inserted_at, updated_at)
    VALUES
      (gen_random_uuid(), 'tenant-1', 'Welcome', 'transactional',
       'a@example.com', 'example.com', 'queued', now(), $1, now(), now())
    #{conflict}
    """

    TestRepo.query(sql, [key])
  end
end
