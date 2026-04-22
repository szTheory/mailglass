defmodule Mailglass.MigrationTest do
  # async: false — these tests inspect and mutate schema-level state.
  use ExUnit.Case, async: false

  @moduletag :phase_02_uat

  alias Mailglass.Migration
  alias Mailglass.TestRepo

  @migrations_path Path.join(:code.priv_dir(:mailglass), "repo/migrations")

  setup do
    # These tests don't use `Mailglass.DataCase` because they exercise the
    # Migration API itself (which issues DDL — CREATE TABLE / DROP TABLE /
    # COMMENT ON TABLE — that cannot be rolled back by a Sandbox transactional
    # wrapper). The "down" test tears the schema down entirely.
    #
    # Switching the sandbox to :auto mode disables ownership tracking entirely
    # for the duration of these tests — every process (including the ephemeral
    # one `Ecto.Migrator.with_repo/2` spawns) checks out on demand, no owner
    # is required. The on_exit reverts to :manual so DataCase tests in the
    # same run remain isolated.
    Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :auto)

    on_exit(fn ->
      # Reapply migrations idempotently so subsequent test files see schema.
      case safe_migrated_version() do
        0 -> _ = safe_migrate_up()
        _ -> :ok
      end

      Ecto.Adapters.SQL.Sandbox.mode(TestRepo, :manual)
    end)

    :ok
  end

  describe "up/0" do
    test "creates mailglass_deliveries, mailglass_events, mailglass_suppressions" do
      # Migrations already ran in test_helper.exs — verify state exists.
      assert table_exists?("mailglass_deliveries")
      assert table_exists?("mailglass_events")
      assert table_exists?("mailglass_suppressions")
    end

    test "installs the mailglass_events_immutable_trigger on mailglass_events" do
      {:ok, %{rows: rows}} =
        TestRepo.query("""
        SELECT trigger_name FROM information_schema.triggers
        WHERE event_object_table = 'mailglass_events'
          AND trigger_name = 'mailglass_events_immutable_trigger'
        """)

      # The trigger is registered for BOTH UPDATE and DELETE, so
      # information_schema returns two rows (one per event action).
      assert rows != []
      assert Enum.all?(rows, fn [name] -> name == "mailglass_events_immutable_trigger" end)
    end

    test "seeds the pg_class comment version marker to 1" do
      assert Migration.migrated_version() == 1
    end

    test "is idempotent — rerunning the migration is a no-op" do
      version_before = Migration.migrated_version()

      # Rerunning through Ecto.Migrator against the already-migrated DB is a
      # no-op because Ecto's schema_migrations tracking skips applied files.
      # Shared-mode sandbox lets the migrator subprocess reuse our connection.
      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.run(repo, @migrations_path, :up, all: true, log: false)
        end)

      assert Migration.migrated_version() == version_before
    end

    test "created all four mailglass_events indexes" do
      {:ok, %{rows: rows}} =
        TestRepo.query("""
        SELECT indexname FROM pg_indexes
        WHERE tablename = 'mailglass_events'
        ORDER BY indexname
        """)

      names = Enum.map(rows, &hd/1)

      # Four custom indexes (idempotency partial, delivery partial, tenant_recent,
      # needs_reconcile partial). The PK index is also present (pkey).
      assert "mailglass_events_idempotency_key_idx" in names
      assert "mailglass_events_delivery_idx" in names
      assert "mailglass_events_tenant_recent_idx" in names
      assert "mailglass_events_needs_reconcile_idx" in names
    end

    test "mailglass_suppressions has stream_scope_check CHECK constraint" do
      {:ok, %{rows: rows}} =
        TestRepo.query("""
        SELECT conname FROM pg_constraint
        WHERE conrelid = 'mailglass_suppressions'::regclass
          AND contype = 'c'
        """)

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
    test "drops all three tables + trigger + function + citext in reverse order" do
      # Roll the schema down through Ecto.Migrator (the same code path adopters
      # hit via `mix ecto.rollback`). :all with :down reverses every applied
      # migration — for V01 only, that drops everything back to the pre-initial
      # state (version 0). Shared-mode sandbox lets the migrator subprocess
      # reuse our owned connection.
      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.run(repo, @migrations_path, :down, all: true, log: false)
        end)

      refute table_exists?("mailglass_deliveries")
      refute table_exists?("mailglass_events")
      refute table_exists?("mailglass_suppressions")

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
      # comment holds the version marker) is gone.
      assert Migration.migrated_version() == 0

      # Reapply so subsequent tests / files in the same run have the schema
      # back. Uses Ecto.Migrator again — same path as test_helper.exs.
      {:ok, _, _} =
        Ecto.Migrator.with_repo(TestRepo, fn repo ->
          Ecto.Migrator.run(repo, @migrations_path, :up, all: true, log: false)
        end)

      assert Migration.migrated_version() == 1
    end
  end

  defp table_exists?(table_name) do
    {:ok, %{rows: rows}} =
      TestRepo.query("""
      SELECT 1 FROM information_schema.tables
      WHERE table_name = '#{table_name}' AND table_schema = 'public'
      """)

    rows != []
  end

  # Variants used in on_exit where the sandbox checkout has been released
  # and we don't want to raise if the TestRepo has already gone down.
  defp safe_migrated_version do
    Migration.migrated_version()
  rescue
    _ -> 0
  end

  defp safe_migrate_up do
    Ecto.Migrator.with_repo(TestRepo, fn repo ->
      Ecto.Migrator.run(repo, @migrations_path, :up, all: true, log: false)
    end)
  rescue
    _ -> :ok
  end
end
