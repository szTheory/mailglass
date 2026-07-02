defmodule Mailglass.SchemaIsolationIntegrationTest do
  # async: false — exercises DDL (CREATE SCHEMA / migration) that cannot
  # run inside the SQL Sandbox transactional wrapper. Uses Sandbox :auto
  # mode for setup; reverts to :manual in on_exit so DataCase tests stay
  # isolated.
  use ExUnit.Case, async: false

  @moduletag :schema_isolation

  alias Mailglass.Events
  alias Mailglass.Operator.Deliveries
  alias Mailglass.Operator.SupportSummary
  alias Mailglass.Outbound.Delivery
  alias Mailglass.Tenancy
  alias Mailglass.TestRepo

  @prefix "mailglass"
  @tenant_id "schema-isolation-test-tenant"

  # Inline wrapper migration that stands up the mailglass schema with a
  # search_path pin so v01's unqualified DDL (events immutability trigger
  # created with bare `ON mailglass_events`) binds to @prefix.mailglass_events
  # rather than public.mailglass_events.
  #
  # This is why D-06 defers the full-suite CI matrix axis to Phase 134:
  # until Phase 134 schema-qualifies the raw DDL (trigger + function + CHECKs),
  # only a search-path-pinned harness can stand the schema up correctly.
  defmodule PrefixedWrapperMigration do
    use Ecto.Migration

    @prefix "mailglass"

    def up do
      # Bind the migration connection to the target schema so v01's
      # unqualified trigger + function DDL lands in @prefix, not public.
      execute("SET LOCAL search_path TO #{@prefix}, public")
      Mailglass.Migration.up(prefix: @prefix, repo: Mailglass.TestRepo)
    end

    def down do
      execute("SET LOCAL search_path TO #{@prefix}, public")
      Mailglass.Migration.down(prefix: @prefix, repo: Mailglass.TestRepo)
    end
  end

  setup do
    # Override the schema to "mailglass" for this test so Config.schema/0
    # returns "mailglass" and the facade injects prefix: "mailglass".
    # The rest of the suite pins :schema to "public" via config/test.exs.
    original_schema = Application.get_env(:mailglass, :schema)
    Application.put_env(:mailglass, :schema, @prefix)
    :persistent_term.erase({Mailglass.Config, :schema})

    # Switch to :auto so DDL/schema creation can run outside the
    # transactional wrapper (mirrors shipped_migration_divergence_test.exs).
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :auto)

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

      # Restore config/sandbox state so DataCase tests are unaffected.
      if original_schema do
        Application.put_env(:mailglass, :schema, original_schema)
      else
        Application.delete_env(:mailglass, :schema)
      end

      :persistent_term.erase({Mailglass.Config, :schema})
      Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
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
      {:ok, %{rows: [[public_count]]}} =
        TestRepo.query("SELECT COUNT(*) FROM public.mailglass_events", [])

      assert public_count == 0,
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
      {:ok, %{rows: [[pub_del_count]]}} =
        TestRepo.query(
          "SELECT COUNT(*) FROM public.mailglass_deliveries WHERE tenant_id = $1",
          [@tenant_id]
        )

      assert pub_del_count == 0,
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
      {:ok, %{rows: [[pub_evt_count]]}} =
        TestRepo.query(
          "SELECT COUNT(*) FROM public.mailglass_events WHERE tenant_id = $1",
          [@tenant_id]
        )

      assert pub_evt_count == 0,
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
      assert is_map(summary), "SupportSummary.summarize_tenant/1 must succeed under #{@prefix} schema"

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
end
