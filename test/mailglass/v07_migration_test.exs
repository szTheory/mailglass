defmodule Mailglass.V07MigrationTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import Mailglass.TestSupport.SandboxOwnership, only: [unsandboxed_module: 1]

  alias Mailglass.Migrations.Postgres
  alias Mailglass.TestRepo
  alias Mailglass.TestSupport.SandboxOwnership

  @moduletag phase_151_task: "t151_03_01"
  @prefix "mailglass_v07_lifecycle_test"
  @decoy_prefix "mailglass_v07_lifecycle_decoy"

  defmodule V06PrerequisitesMigration do
    use Ecto.Migration
    @prefix "mailglass_v07_lifecycle_test"

    def up do
      Enum.each(1..6, fn version ->
        module = Module.concat([Mailglass.Migrations.Postgres, "V0#{version}"])
        apply(module, :up, [[prefix: @prefix]])
      end)
    end

    def down, do: :ok
  end

  defmodule V07UpMigration do
    use Ecto.Migration
    @prefix "mailglass_v07_lifecycle_test"
    def up, do: Postgres.V07.up(prefix: @prefix)
    def down, do: :ok
  end

  defmodule V07DownMigration do
    use Ecto.Migration
    @prefix "mailglass_v07_lifecycle_test"
    def up, do: Postgres.V07.down(prefix: @prefix)
    def down, do: :ok
  end

  setup :unsandboxed_module

  setup do
    prefix = SandboxOwnership.scratch_schema!(@prefix, caller: __MODULE__)
    decoy_prefix = SandboxOwnership.scratch_schema!(@decoy_prefix, caller: __MODULE__)
    version = System.system_time(:microsecond)

    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
    {:ok, _} = TestRepo.query("DROP SCHEMA IF EXISTS #{@decoy_prefix} CASCADE")
    {:ok, _} = TestRepo.query("CREATE SCHEMA #{@prefix}")
    {:ok, _} = TestRepo.query("CREATE SCHEMA #{@decoy_prefix}")

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.up(repo, version, V06PrerequisitesMigration, log: false)
      end)

    {:ok, _} = TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])

    on_exit(fn ->
      _ = TestRepo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
      _ = TestRepo.query("DROP SCHEMA IF EXISTS #{@decoy_prefix} CASCADE")
      SandboxOwnership.assert_baseline_intact!(TestRepo, __MODULE__)
    end)

    {:ok, prefix: prefix, decoy_prefix: decoy_prefix}
  end

  test "V06 rows upgrade to the closed lifecycle catalog under a hostile search path", %{
    prefix: prefix,
    decoy_prefix: decoy_prefix
  } do
    delivery_id = Ecto.UUID.generate()
    insert_v06_payload!(prefix, delivery_id)
    create_decoy_objects!(decoy_prefix)

    with_hostile_search_path!(decoy_prefix, fn -> run_v07_step!(V07UpMigration) end)

    assert lifecycle_states(prefix) == [
             "abandoned",
             "discarded",
             "dispatching",
             "expired",
             "legacy",
             "recoverable",
             "scrubbed",
             "terminal",
             "uncertain"
           ]

    assert payload_row(prefix, delivery_id) == ["recoverable", nil, nil, %{"version" => 1}]
    assert index_exists?(prefix, "mailglass_outbound_payloads_state_expires_at_idx")
    refute index_exists?(decoy_prefix, "mailglass_outbound_payloads_state_expires_at_idx")
  end

  test "down refuses before DDL for claimed or contentless lifecycle facts", %{
    prefix: prefix,
    decoy_prefix: decoy_prefix
  } do
    delivery_id = Ecto.UUID.generate()
    insert_v06_payload!(prefix, delivery_id)
    with_hostile_search_path!(decoy_prefix, fn -> run_v07_step!(V07UpMigration) end)

    TestRepo.query!(
      "UPDATE #{prefix}.mailglass_outbound_payloads SET lifecycle_state = 'scrubbed', reason_class = 'accepted', envelope = NULL, scrubbed_at = now()"
    )

    assert_raise Postgrex.Error, ~r/V07 downgrade refused/, fn ->
      with_hostile_search_path!(decoy_prefix, fn -> run_v07_step!(V07DownMigration) end)
    end

    assert payload_columns(prefix) |> Enum.map(&hd/1) |> Enum.member?("lifecycle_state")
    assert payload_row(prefix, delivery_id) |> hd() == "scrubbed"
  end

  test "clean recoverable rows down and re-up with the exact V06 catalog", %{
    prefix: prefix,
    decoy_prefix: decoy_prefix
  } do
    delivery_id = Ecto.UUID.generate()
    insert_v06_payload!(prefix, delivery_id)
    with_hostile_search_path!(decoy_prefix, fn -> run_v07_step!(V07UpMigration) end)
    with_hostile_search_path!(decoy_prefix, fn -> run_v07_step!(V07DownMigration) end)

    assert payload_columns(prefix) == v06_payload_columns()
    refute index_exists?(prefix, "mailglass_outbound_payloads_state_expires_at_idx")

    with_hostile_search_path!(decoy_prefix, fn -> run_v07_step!(V07UpMigration) end)
    assert payload_row(prefix, delivery_id) == ["recoverable", nil, nil, %{"version" => 1}]
  end

  defp insert_v06_payload!(prefix, delivery_id) do
    TestRepo.query!(
      """
      INSERT INTO #{prefix}.mailglass_deliveries
        (id, tenant_id, mailable, stream, recipient, recipient_domain, last_event_type,
         last_event_at, metadata, status, inserted_at, updated_at)
      VALUES ($1::text::uuid, 'tenant-v07', 'Mailglass.LegacyMailer', 'transactional',
              'v07@example.test', 'example.test', 'queued', now(), '{}'::jsonb, 'queued', now(), now())
      """,
      [delivery_id]
    )

    TestRepo.query!(
      """
      INSERT INTO #{prefix}.mailglass_outbound_payloads
        (id, tenant_id, delivery_id, envelope_version, envelope_digest, envelope, inserted_at, updated_at)
      VALUES (gen_random_uuid(), 'tenant-v07', $1::text::uuid, 1, 'digest', '{"version": 1}'::jsonb, now(), now())
      """,
      [delivery_id]
    )
  end

  defp run_v07_step!(migration) do
    version = System.system_time(:microsecond)

    {:ok, _, _} =
      Ecto.Migrator.with_repo(TestRepo, fn repo ->
        Ecto.Migrator.up(repo, version, migration, log: false)
      end)

    {:ok, _} = TestRepo.query("DELETE FROM schema_migrations WHERE version = $1", [version])
    :ok
  end

  defp with_hostile_search_path!(decoy_prefix, fun) do
    SandboxOwnership.with_search_path!("#{decoy_prefix}, public", fun,
      repo: TestRepo,
      caller: __MODULE__
    )
  end

  defp create_decoy_objects!(prefix) do
    TestRepo.query!(
      "CREATE TABLE #{prefix}.mailglass_outbound_payloads (id uuid PRIMARY KEY, delivery_id uuid NOT NULL)"
    )
  end

  defp lifecycle_states(prefix) do
    %{rows: [[definition]]} =
      TestRepo.query!(
        "SELECT pg_get_constraintdef(con.oid) FROM pg_constraint AS con JOIN pg_class AS table_data ON table_data.oid = con.conrelid JOIN pg_namespace AS namespace_data ON namespace_data.oid = table_data.relnamespace WHERE namespace_data.nspname = $1 AND table_data.relname = 'mailglass_outbound_payloads' AND con.conname = 'mailglass_outbound_payloads_lifecycle_state_check'",
        [prefix]
      )

    Regex.scan(~r/'([^']+)'/, definition, capture: :all_but_first)
    |> List.flatten()
    |> Enum.sort()
  end

  defp payload_row(prefix, delivery_id) do
    %{rows: [row]} =
      TestRepo.query!(
        "SELECT lifecycle_state, reason_class, claimed_at, envelope FROM #{prefix}.mailglass_outbound_payloads WHERE delivery_id = $1::text::uuid",
        [delivery_id]
      )

    row
  end

  defp payload_columns(prefix) do
    %{rows: rows} =
      TestRepo.query!(
        "SELECT a.attname, pg_catalog.format_type(a.atttypid, a.atttypmod), a.attnotnull FROM pg_catalog.pg_attribute AS a JOIN pg_catalog.pg_class AS c ON c.oid = a.attrelid JOIN pg_catalog.pg_namespace AS n ON n.oid = c.relnamespace WHERE n.nspname = $1 AND c.relname = 'mailglass_outbound_payloads' AND a.attnum > 0 AND NOT a.attisdropped ORDER BY a.attnum",
        [prefix]
      )

    rows
  end

  defp v06_payload_columns do
    [
      ["id", "uuid", true], ["tenant_id", "text", true], ["delivery_id", "uuid", true],
      ["envelope_version", "integer", true], ["envelope_digest", "text", true],
      ["envelope", "jsonb", true], ["scrubbed_at", "timestamp without time zone", false],
      ["expires_at", "timestamp without time zone", false],
      ["inserted_at", "timestamp without time zone", true], ["updated_at", "timestamp without time zone", true]
    ]
  end

  defp index_exists?(prefix, name) do
    %{rows: rows} = TestRepo.query!("SELECT 1 FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace WHERE n.nspname = $1 AND c.relname = $2 AND c.relkind = 'i'", [prefix, name])
    rows != []
  end
end
