defmodule Mix.Tasks.Mailglass.Inbound.Gen.MigrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  defmodule HostRepo do
    def config,
      do: [otp_app: :mailglass_inbound, priv: "tmp/mailglass_inbound_gen_migration_test/priv/repo"]

    def __adapter__, do: Ecto.Adapters.Postgres

    def query(query, params, options) do
      send(self(), {:host_query, query, params, options})
      Process.get(:host_catalog_result, {:ok, %{rows: [["1"]]}})
    end
  end

  defmodule OtherRepo do
    def config,
      do: [
        otp_app: :mailglass_inbound,
        priv: "tmp/mailglass_inbound_gen_migration_test/priv/other_repo"
      ]

    def __adapter__, do: UnsupportedAdapter

    def query(_query, _params, _options) do
      send(self(), :other_repo_called)
      {:ok, %{rows: [["1"]]}}
    end
  end

  setup do
    File.rm_rf!(migrations_path())
    prior = Application.get_env(:mailglass_inbound, :ecto_repos)

    on_exit(fn ->
      restore_ecto_repos(:mailglass_inbound, prior)
      File.rm_rf!(migrations_path())
    end)

    :ok
  end

  test "generates the stable inbound wrapper for the one configured repo" do
    Application.put_env(:mailglass_inbound, :ecto_repos, [HostRepo])

    assert capture_io(fn -> Mix.Tasks.Mailglass.Inbound.Gen.Migration.run([]) end) =~ "created"

    assert [path] = migration_paths()

    assert File.read!(path) == """
           defmodule Mix.Tasks.Mailglass.Inbound.Gen.MigrationTest.HostRepo.Migrations.MailglassInboundInstall do
             use Ecto.Migration

             def up, do: MailglassInbound.Migration.up(repo: Mix.Tasks.Mailglass.Inbound.Gen.MigrationTest.HostRepo)
             def down, do: MailglassInbound.Migration.down(repo: Mix.Tasks.Mailglass.Inbound.Gen.MigrationTest.HostRepo)
           end
           """
  end

  test "rejects ambiguous repo selection without writing" do
    Application.put_env(:mailglass_inbound, :ecto_repos, [HostRepo, OtherRepo])

    assert_raise Mix.Error, ~r/exactly one configured Ecto repo/, fn ->
      Mix.Tasks.Mailglass.Inbound.Gen.Migration.run([])
    end

    assert migration_paths() == []
  end

  test "generates a transaction-disabled offline upgrade from V01" do
    Application.put_env(:mailglass_inbound, :ecto_repos, [HostRepo])

    assert capture_io(fn ->
             Mix.Tasks.Mailglass.Inbound.Gen.Migration.run(["--upgrade", "--from", "1"])
           end) =~ "created"

    assert [path] = migration_paths()
    source = File.read!(path)

    assert source =~ "@disable_ddl_transaction true"
    assert source =~ "@disable_migration_lock true"
    assert source =~ "non_transactional_wrapper: true"

    assert source =~
             "MailglassInbound.Migration.down(repo: Mix.Tasks.Mailglass.Inbound.Gen.MigrationTest.HostRepo, version: 1, non_transactional_wrapper: true)"
  end

  test "uses the selected repo for live inbound inspection and generates the V01 upgrade" do
    Application.put_env(:mailglass_inbound, :ecto_repos, [HostRepo])
    prior_repo = Application.get_env(:mailglass_inbound, :repo)
    Application.put_env(:mailglass_inbound, :repo, OtherRepo)

    on_exit(fn -> restore_repo(:mailglass_inbound, prior_repo) end)

    assert capture_io(fn ->
             Mailglass.MigrationGenerator.run(inbound_spec(), ["--upgrade"],
               with_repo: fn repo, fun ->
                 send(self(), {:started_repo, repo})
                 {:ok, fun.(repo), []}
               end
             )
           end) =~ "created"

    assert_received {:started_repo, HostRepo}
    assert_received {:host_query, query, [schema], [log: false]}
    assert schema == MailglassInbound.Config.schema()
    assert query =~ "mailglass_inbound_records"
    refute_received :other_repo_called
    assert [path] = migration_paths()
    assert File.read!(path) =~ "version: 1, non_transactional_wrapper: true"
  end

  defp migration_paths do
    migrations_path()
    |> Path.join("*.exs")
    |> Path.wildcard()
    |> Enum.sort()
  end

  defp migrations_path, do: Ecto.Migrator.migrations_path(HostRepo)

  defp inbound_spec do
    %{
      task_name: "mailglass.inbound.gen.migration",
      install_suffix: "mailglass_inbound_install",
      upgrade_suffix: "mailglass_inbound_upgrade",
      install_module_suffix: "MailglassInboundInstall",
      upgrade_module_suffix: "MailglassInboundUpgrade",
      migration_module: MailglassInbound.Migration,
      initial_version: &MailglassInbound.Migrations.Postgres.initial_version/0,
      current_version: &MailglassInbound.Migrations.Postgres.current_version/0
    }
  end

  defp restore_ecto_repos(app, nil), do: Application.delete_env(app, :ecto_repos)
  defp restore_ecto_repos(app, repos), do: Application.put_env(app, :ecto_repos, repos)

  defp restore_repo(app, nil), do: Application.delete_env(app, :repo)
  defp restore_repo(app, repo), do: Application.put_env(app, :repo, repo)
end
