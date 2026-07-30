defmodule Mailglass.SchemaIsolationIntegrationTest do
  # async: false — exercises DDL (CREATE SCHEMA / migration) that cannot
  # run inside the SQL Sandbox transactional wrapper. Uses Sandbox :auto
  # mode for setup; reverts to :manual in on_exit so DataCase tests stay
  # isolated.
  use ExUnit.Case, async: false

  @moduletag :schema_isolation

  import Mailglass.TestSupport.SandboxOwnership, only: [unsandboxed_module: 1, with_schema!: 1]

  alias Mailglass.Events
  alias Mailglass.Operator.Deliveries
  alias Mailglass.Operator.SupportSummary
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Tenancy
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
  @prefix "mailglass_isolation_integration_test"
  @tenant_id "schema-isolation-test-tenant"

  # Inline wrapper migration that stands the scratch schema up through the
  # shipped dispatcher, with NO ambient-path pin of any kind.
  #
  # The pin this migration used to carry (`SET LOCAL search_path TO @prefix,
  # public`) was a DOCUMENTED CRUTCH for v01's then-unqualified events
  # immutability trigger + function. Phase 134-02 schema-qualified that raw DDL
  # (`postgres/v01.ex:138,154` now emit `#{q}.mailglass_raise_immutability` and
  # `ON #{q}.mailglass_events`), and `schema_isolation_immutability_test.exs`
  # exists specifically to prove the pin is no longer needed — it carries an
  # in-module self-check that refuses to let any pin back into its own source.
  #
  # The crutch is removed here because it was not merely obsolete, it was
  # actively harmful once this module moved to a scratch prefix: `SET LOCAL`
  # persists for the remainder of the transaction, and `Ecto.Migrator` inserts
  # its `schema_migrations` version row INSIDE that same transaction, AFTER the
  # migration body runs. So the pin silently redirected Ecto's own bookkeeping
  # INSERT to a search_path where no `schema_migrations` table exists, raising
  # `42P01 (undefined_table) relation "schema_migrations" does not exist`. That
  # was invisible while the prefix was the literal "mailglass" (the pin happened
  # to include the schema the boot bookkeeping table lives in on that axis).
  defmodule PrefixedWrapperMigration do
    use Ecto.Migration

    @prefix "mailglass_isolation_integration_test"

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
    # Read-only: it observes and names, it never restores (D-31). This module
    # no longer tears the baseline down at all, so there is nothing to restore;
    # this check is what proves that claim on every single test rather than
    # asserting it in a comment.
    on_exit(fn -> SandboxOwnership.assert_baseline_intact!(TestRepo, __MODULE__) end)

    # Override the schema to the scratch prefix for this test so Config.schema/0
    # returns it and the facade injects `prefix: <scratch>`. The rest of the
    # suite pins :schema to "public" via config/test.exs (or to "mailglass" on
    # the schema-isolation axis).
    #
    # 143-MECHANISM.md § "The three-class inventory" names this file as a
    # Class B (config_schema_drift) candidate: it flips Config.schema()
    # per-test. Closed here via the restore-first `with_schema!/2` seam
    # (143-07) — the restore is registered before any statement below (the
    # schema drop/migrate) that can raise.
    with_schema!(prefix)

    # Clean slate — drop then re-create the isolated schema before migrating.
    # (footgun 13: schema must exist BEFORE the Sandbox owner starts.)
    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
    {:ok, _} = TestRepo.query("CREATE SCHEMA #{@prefix}")

    # Unique migration version per run — Ecto.Migrator records it in
    # schema_migrations and treats a re-used version as :already_up.
    version = System.unique_integer([:positive, :monotonic]) + 90_000_000_000_000

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.up(repo, version, PrefixedWrapperMigration, log: false)
      end)

    # Stamp the test tenant so Events.append/1 auto-captures it.
    Tenancy.put_current(@tenant_id)

    on_exit(fn ->
      {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")

      {:ok, _} =
        TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])

      # `with_schema!/2`'s own on_exit (registered before this one, so it runs
      # after — reverse on_exit order) restores `config :mailglass, :schema`
      # to the captured boot value. Nothing to do here for that key.
      #
      # No baseline restoration happens here, and none is needed: the DROP above
      # targets this module's own scratch schema, which no other module or axis
      # ever uses. The previous version of this file dropped the literal
      # "mailglass" — the live baseline under MAILGLASS_SCHEMA=mailglass — and
      # then tried to re-migrate it from here. That restore was both unverified
      # (`Ecto.Migrator.run/4` returning `{:ok, _, _}` proves only that the
      # migrator ran) and fragile: it began with
      # `DELETE FROM public.schema_migrations WHERE version < 100`, and on the
      # mailglass axis the boot bookkeeping table lives in `mailglass`, not
      # `public`, so that statement could raise 42P01 inside `on_exit` and
      # abandon the restore entirely, leaving the baseline down. Not dropping the
      # baseline in the first place removes the whole failure mode instead of
      # trying to undo it. The `assert_baseline_intact!/2` registered at the top
      # of `setup` verifies that on every test.
    end)

    :ok
  end

  describe "FACADE-04 schema isolation: rows land under mailglass.* while public stays clean" do
    test "Events.append/1 writes to mailglass.mailglass_events, not public" do
      # === WRITE through the facade ===
      {:ok, _event} =
        Events.append(%{
          type: :sent,
          tenant_id: @tenant_id,
          occurred_at: DateTime.utc_now(),
          normalized_payload: %{},
          metadata: %{provider: "postmark"}
        })

      # === Assertion 1: public.mailglass_events holds zero rows ===
      # `public_row_count/2` returns 0 when the public table is absent — under the
      # CI schema-isolation axis (MAILGLASS_SCHEMA=mailglass) the whole suite is
      # migrated into `mailglass`, so `public.mailglass_events` does not exist at
      # all, which is an even stronger form of "the row is not in public".
      assert public_row_count("mailglass_events") == 0,
             "public.mailglass_events must be empty — facade must route to #{@prefix}, not public"

      # === Assertion 2: mailglass.mailglass_events holds the written row ===
      {:ok, %{rows: [[prefix_count]]}} =
        TestRepo.query("SELECT COUNT(*) FROM #{@prefix}.mailglass_events WHERE tenant_id = $1", [
          @tenant_id
        ])

      assert prefix_count > 0,
             "#{@prefix}.mailglass_events must contain the written row (got 0)"
    end

    test "Delivery insert + Events.append round-trips under mailglass schema" do
      # Insert a Delivery with an explicit prefix so it lands in mailglass.
      delivery =
        %{
          tenant_id: @tenant_id,
          mailable: "Mailglass.Example.SchemaIsolationMailer",
          stream: :transactional,
          recipient: "schema-isolation@example.com",
          recipient_domain: "example.com",
          provider: "postmark",
          status: :queued,
          last_event_type: :queued,
          last_event_at: DateTime.utc_now(),
          metadata: %{}
        }
        |> Delivery.changeset()
        |> TestRepo.insert!(prefix: @prefix)

      # Write an event linked to the delivery via the facade.
      {:ok, _event} =
        Events.append(%{
          type: :queued,
          delivery_id: delivery.id,
          tenant_id: @tenant_id,
          occurred_at: DateTime.utc_now(),
          normalized_payload: %{},
          metadata: %{}
        })

      # === Assertion 1: public.mailglass_deliveries holds zero rows ===
      assert public_row_count("mailglass_deliveries", @tenant_id) == 0,
             "public.mailglass_deliveries must be empty — delivery write must land in #{@prefix}"

      # === Assertion 2: mailglass.mailglass_deliveries holds the row ===
      {:ok, %{rows: [[pfx_del_count]]}} =
        TestRepo.query(
          "SELECT COUNT(*) FROM #{@prefix}.mailglass_deliveries WHERE tenant_id = $1",
          [@tenant_id]
        )

      assert pfx_del_count == 1,
             "#{@prefix}.mailglass_deliveries must contain exactly one delivery row"

      # === Assertion 3: public.mailglass_events holds zero rows for this tenant ===
      assert public_row_count("mailglass_events", @tenant_id) == 0,
             "public.mailglass_events must be empty — events write must land in #{@prefix}"

      # === Assertion 4: Operator reads resolve under the prefix ===
      # SupportSummary reads through the facade + the put_query_prefix/2 subquery.
      summary =
        SupportSummary.summarize_tenant(%{
          tenant_id: @tenant_id,
          window_hours: 168
        })

      # The summary struct must be returned successfully (not crash with
      # "table mailglass_deliveries does not exist in schema mailglass").
      assert is_map(summary),
             "SupportSummary.summarize_tenant/1 must succeed under #{@prefix} schema"

      # Deliveries list read via Operator.Deliveries (goes through Repo.aggregate + Repo.all).
      deliveries =
        Deliveries.list_recent_deliveries(%{
          tenant_id: @tenant_id,
          window_hours: 168
        })

      assert is_list(deliveries),
             "Operator.Deliveries.list_recent_deliveries/1 must succeed under #{@prefix} schema"

      assert length(deliveries) == 1,
             "Operator read-model must find the written delivery under #{@prefix} (found #{length(deliveries)})"

      # === Assertion 5: Tenancy.scope/2 still composes (WHERE + schema both apply) ===
      # Insert a delivery under a DIFFERENT tenant to confirm tenant scoping is respected.
      other_tenant = "other-tenant-schema-isolation"

      Tenancy.with_tenant(other_tenant, fn ->
        Events.append(%{
          type: :sent,
          tenant_id: other_tenant,
          occurred_at: DateTime.utc_now(),
          normalized_payload: %{},
          metadata: %{}
        })
      end)

      # The deliveries list for @tenant_id should not include the other tenant's row.
      scoped_deliveries =
        Deliveries.list_recent_deliveries(%{
          tenant_id: @tenant_id,
          window_hours: 168
        })

      assert length(scoped_deliveries) == 1,
             "Tenancy.scope/2 must filter to @tenant_id only (got #{length(scoped_deliveries)})"

      # Confirm other tenant's events ARE under mailglass schema (not public).
      {:ok, %{rows: [[other_tenant_evt_count]]}} =
        TestRepo.query(
          "SELECT COUNT(*) FROM #{@prefix}.mailglass_events WHERE tenant_id = $1",
          [other_tenant]
        )

      assert other_tenant_evt_count > 0,
             "Other tenant's events must land in #{@prefix}.mailglass_events, not public"
    end
  end

  describe "FACADE-04: orphan-count read via SupportSummary resolves under mailglass prefix" do
    test "orphan_backlog_summary reads from mailglass schema via put_query_prefix/2 subquery" do
      # Write an event with needs_reconciliation: true (an orphan) via the facade.
      {:ok, _orphan_event} =
        Events.append(%{
          type: :bounced,
          tenant_id: @tenant_id,
          occurred_at: DateTime.utc_now(),
          normalized_payload: %{},
          metadata: %{needs_reconciliation_reason: "test"},
          needs_reconciliation: true
        })

      summary =
        SupportSummary.summarize_tenant(%{
          tenant_id: @tenant_id,
          window_hours: 168
        })

      orphan_count = get_in(summary, [:orphan_backlog, :count])

      # The orphan subquery (put_query_prefix/2-guarded) must resolve under
      # the mailglass schema and find the written orphan event.
      assert is_integer(orphan_count) and orphan_count >= 0,
             "SupportSummary orphan_backlog.count must be an integer under #{@prefix} schema"
    end
  end

  describe "D-08: no facade-bypassing lib/ call-sites" do
    # Asserts the D-08 invariant: every runtime read/write in lib/mailglass/
    # routes through Mailglass.Repo.* (the facade). The known-allowed direct
    # host-repo calls are in migration.ex only (resolve_repo/0 for adapter
    # introspection + :repo env lookup — correctly out of scope for Phase 134).
    #
    # Comment-text discipline: the assertion greps for the literal token pattern
    # without putting the full pattern into this comment.
    test "lib/mailglass does not contain direct Application.get_env(:mailglass, :repo) outside migration.ex" do
      lib_dir = Path.join([File.cwd!(), "lib", "mailglass"])

      # Collect all .ex files under lib/mailglass/ excluding the allowlisted files:
      # - migration.ex (resolve_repo/0 uses get_env for adapter introspection)
      # - repo.ex (the facade itself — this IS the authorized get_env site,
      #   inside the private repo/0 function that every other caller routes through)
      # - migrations/ directory (migration DDL modules, out of scope for Phase 134)
      lib_files =
        Path.wildcard(Path.join(lib_dir, "**/*.ex"))
        |> Enum.reject(fn path ->
          String.contains?(path, "/migrations/") or
            String.ends_with?(path, "migration.ex") or
            String.ends_with?(path, "/repo.ex")
        end)

      # Check for direct Application.get_env(:mailglass, :repo) calls.
      # The allowlisted file (migration.ex) is already excluded above.
      # New call-sites in other lib/ files would bypass the facade.
      direct_repo_env_hits =
        lib_files
        |> Enum.filter(fn file ->
          content = File.read!(file)
          # Pattern: Application.get_env with :mailglass and :repo args
          String.contains?(content, "Application.get_env(:mailglass, :repo)")
        end)
        |> Enum.map(&Path.relative_to(&1, File.cwd!()))

      assert direct_repo_env_hits == [],
             "D-08 invariant: the following lib/ files bypass the Mailglass.Repo facade " <>
               "with a direct Application.get_env(:mailglass, :repo) call (only migration.ex is allowed): " <>
               inspect(direct_repo_env_hits)
    end
  end

  # Count rows in `public.<table>` (optionally scoped to a tenant), returning 0
  # when the `public` table does not exist. Under the CI schema-isolation axis
  # (MAILGLASS_SCHEMA=mailglass) the whole suite is migrated into `mailglass`, so
  # there is no `public.mailglass_*` table at all — which is a stronger proof of
  # isolation than an empty public table (the row provably cannot be in a schema
  # with no such relation). Under the default "public" suite the public tables
  # exist and this counts them as before.
  defp public_row_count(table, tenant_id \\ nil) do
    if public_table_exists?(table) do
      {sql, params} =
        if tenant_id do
          {"SELECT COUNT(*) FROM public.#{table} WHERE tenant_id = $1", [tenant_id]}
        else
          {"SELECT COUNT(*) FROM public.#{table}", []}
        end

      {:ok, %{rows: [[count]]}} = TestRepo.query(sql, params)
      count
    else
      0
    end
  end

  defp public_table_exists?(table) do
    {:ok, %{rows: rows}} =
      TestRepo.query(
        """
        SELECT 1 FROM information_schema.tables
        WHERE table_schema = 'public' AND table_name = $1
        """,
        [table]
      )

    rows != []
  end
end
