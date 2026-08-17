defmodule LegacyRepairHost.Repo do
  use Ecto.Repo,
    otp_app: :mailglass,
    adapter: Ecto.Adapters.Postgres
end

defmodule Mix.Tasks.Mailglass.LegacyRepairTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  import Mailglass.TestSupport.SandboxOwnership, only: [unsandboxed_module: 1]

  @prefix "mailglass_legacy_repair_test"
  @version 155_040_001
  @migrations_path "tmp/mailglass_legacy_repair_test/migrations"

  alias LegacyRepairHost.Repo

  setup :unsandboxed_module

  setup do
    previous_repos = Application.get_env(:mailglass, :ecto_repos)
    previous_repo_config = Application.get_env(:mailglass, Repo)
    Application.put_env(:mailglass, :ecto_repos, [Repo])
    Application.put_env(:mailglass, Repo, repo_config())

    source_path = Path.join(@migrations_path, "20240101000000_mailglass_install.exs")
    File.rm_rf!(@migrations_path)
    File.mkdir_p!(Path.dirname(source_path))
    File.write!(source_path, legacy_source())

    if pid = Process.whereis(Repo) do
      try do
        GenServer.stop(pid, :normal)
      catch
        :exit, _reason -> :ok
      end
    end

    case Repo.start_link() do
      {:ok, _pid} -> :ok
      {:error, {:already_started, _pid}} -> :ok
    end

    {:ok, _} = Repo.query("DROP SCHEMA IF EXISTS #{@prefix} CASCADE")
    {:ok, _} = Repo.query("CREATE SCHEMA #{@prefix}")
    {:ok, _} = Repo.query("DELETE FROM schema_migrations WHERE version = $1", [@version])
    create_legacy_table!()

    on_exit(fn ->
      restore_env(:ecto_repos, previous_repos)
      restore_env(Repo, previous_repo_config)
      File.rm_rf!(@migrations_path)
    end)

    %{source_path: source_path}
  end

  test "repairs one exact empty historical toy and rolls it back", %{source_path: source_path} do
    assert capture_io(fn ->
             Mailglass.MigrationGenerator.run(core_spec(), ["--repair-legacy"],
               with_repo: fn repo, fun -> {:ok, fun.(repo), []} end
             )
           end) =~ "created"

    assert File.read!(source_path) == legacy_source()
    assert [^source_path, repair_path] = migration_paths()

    {{:module, repair_module, _, _}, _} = Code.eval_string(File.read!(repair_path))
    assert {:module, repair_module} = Code.ensure_loaded(repair_module)

    :ok = Ecto.Migrator.up(Repo, @version, repair_module, log: false)

    assert Mailglass.Migration.migrated_version(prefix: @prefix, repo: Repo) ==
             Mailglass.Migrations.Postgres.current_version()

    assert table_exists?("mailglass_deliveries")

    :ok = Ecto.Migrator.down(Repo, @version, repair_module, log: false)

    assert legacy_signature?()
    assert File.read!(source_path) == legacy_source()
  end

  test "refuses altered and ambiguous legacy source without writing", %{source_path: source_path} do
    File.write!(source_path, legacy_source() <> "\n")
    before = migration_snapshot()

    assert_raise Mix.Error, ~r/source is ambiguous/, fn ->
      Mailglass.MigrationGenerator.run(core_spec(), ["--repair-legacy"],
        with_repo: fn repo, fun -> {:ok, fun.(repo), []} end
      )
    end

    assert migration_snapshot() == before

    File.write!(source_path, legacy_source())

    File.write!(
      Path.join(@migrations_path, "20240101000001_mailglass_install.exs"),
      legacy_source()
    )

    before = migration_snapshot()

    assert_raise Mix.Error, ~r/multiple legacy source candidates/, fn ->
      Mailglass.MigrationGenerator.run(core_spec(), ["--repair-legacy"])
    end

    assert migration_snapshot() == before
  end

  test "refuses a populated toy table and preserves its sentinel row" do
    {:ok, _} =
      Repo.query(
        "INSERT INTO #{@prefix}.mailglass_events (tenant_id, inserted_at, updated_at) VALUES ('sentinel', now(), now())"
      )

    before = migration_snapshot()

    assert_raise Mix.Error, ~r/table is populated/, fn ->
      Mailglass.MigrationGenerator.run(core_spec(), ["--repair-legacy"],
        with_repo: fn repo, fun -> {:ok, fun.(repo), []} end
      )
    end

    assert migration_snapshot() == before

    assert {:ok, %{rows: [["sentinel"]]}} =
             Repo.query("SELECT tenant_id FROM #{@prefix}.mailglass_events")
  end

  test "refuses altered catalog and missing source without writing" do
    {:ok, _} = Repo.query("ALTER TABLE #{@prefix}.mailglass_events ADD COLUMN forged text")
    before = migration_snapshot()

    assert_raise Mix.Error, ~r/catalog is ambiguous/, fn ->
      Mailglass.MigrationGenerator.run(core_spec(), ["--repair-legacy"],
        with_repo: fn repo, fun -> {:ok, fun.(repo), []} end
      )
    end

    assert migration_snapshot() == before

    [source_path] = migration_paths()
    File.rename!(source_path, source_path <> ".hidden")
    before = migration_snapshot()

    assert_raise Mix.Error, ~r/source is missing/, fn ->
      Mailglass.MigrationGenerator.run(core_spec(), ["--repair-legacy"])
    end

    assert migration_snapshot() == before
  end

  test "inbound task declares legacy repair unsupported before invoking the generator" do
    source = File.read!("mailglass_inbound/lib/mix/tasks/mailglass.inbound.gen.migration.ex")

    assert source =~ "--repair-legacy"
    assert source =~ "no recognized inbound legacy signature"
  end

  defp create_legacy_table! do
    {:ok, _} =
      Repo.query("""
      CREATE TABLE #{@prefix}.mailglass_events (
        id bigint GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
        tenant_id varchar,
        inserted_at timestamp(6) NOT NULL,
        updated_at timestamp(6) NOT NULL
      )
      """)
  end

  defp legacy_signature? do
    {:ok, %{rows: [[count]]}} =
      Repo.query(
        "SELECT count(*) FROM information_schema.columns WHERE table_schema = $1 AND table_name = 'mailglass_events'",
        [@prefix]
      )

    count == 4
  end

  defp table_exists?(table) do
    {:ok, %{rows: rows}} =
      Repo.query(
        "SELECT 1 FROM information_schema.tables WHERE table_schema = $1 AND table_name = $2",
        [@prefix, table]
      )

    rows != []
  end

  defp migration_paths do
    @migrations_path
    |> Path.join("*.exs")
    |> Path.wildcard()
    |> Enum.sort()
  end

  defp migration_snapshot do
    migration_paths()
    |> Enum.map(&{&1, File.read!(&1)})
  end

  defp repo_config do
    Application.fetch_env!(:mailglass, Mailglass.TestRepo)
    |> Keyword.put(:priv, "tmp/mailglass_legacy_repair_test/priv/repo")
    |> Keyword.put(:pool, DBConnection.ConnectionPool)
    |> Keyword.put(:name, Repo)
  end

  defp restore_env(key, nil), do: Application.delete_env(:mailglass, key)
  defp restore_env(key, value), do: Application.put_env(:mailglass, key, value)

  defp legacy_source do
    """
    defmodule LegacyRepairHost.Repo.Migrations.MailglassInstall do
      use Ecto.Migration

      def change do
        create table(:mailglass_events) do
          add :tenant_id, :string
          timestamps(type: :utc_datetime_usec)
        end
      end
    end
    """
  end

  defp core_spec do
    %{
      task_name: "mailglass.gen.migration",
      install_suffix: "mailglass_install",
      upgrade_suffix: "mailglass_upgrade",
      install_module_suffix: "MailglassInstall",
      upgrade_module_suffix: "MailglassUpgrade",
      migration_module: Mailglass.Migration,
      initial_version: &Mailglass.Migrations.Postgres.initial_version/0,
      current_version: &Mailglass.Migrations.Postgres.current_version/0,
      legacy_app_module: LegacyRepairHost,
      legacy_prefix: @prefix,
      migrations_path: fn Repo -> @migrations_path end
    }
  end
end
