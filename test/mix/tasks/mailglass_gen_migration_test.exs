defmodule Mix.Tasks.Mailglass.Gen.MigrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  defmodule HostRepo do
    def config, do: [otp_app: :mailglass, priv: "tmp/mailglass_gen_migration_test/priv/repo"]
    def __adapter__, do: Ecto.Adapters.Postgres

    def query(query, params, options) do
      send(self(), {:host_query, query, params, options})
      Process.get(:host_catalog_result, {:ok, %{rows: [["4"]]}})
    end
  end

  defmodule OtherRepo do
    def config, do: [otp_app: :mailglass, priv: "tmp/mailglass_gen_migration_test/priv/other_repo"]
    def __adapter__, do: UnsupportedAdapter

    def query(_query, _params, _options) do
      send(self(), :other_repo_called)
      {:ok, %{rows: [["1"]]}}
    end
  end

  setup do
    File.rm_rf!(migrations_path())
    prior = Application.get_env(:mailglass, :ecto_repos)

    on_exit(fn ->
      restore_ecto_repos(:mailglass, prior)
      File.rm_rf!(migrations_path())
    end)

    :ok
  end

  test "generates the stable core wrapper for the one configured repo" do
    Application.put_env(:mailglass, :ecto_repos, [HostRepo])

    assert capture_io(fn -> Mix.Tasks.Mailglass.Gen.Migration.run([]) end) =~ "created"

    assert [path] = migration_paths()

    assert File.read!(path) == """
           defmodule Mix.Tasks.Mailglass.Gen.MigrationTest.HostRepo.Migrations.MailglassInstall do
             use Ecto.Migration

             def up, do: Mailglass.Migration.up(repo: Mix.Tasks.Mailglass.Gen.MigrationTest.HostRepo)
             def down, do: Mailglass.Migration.down(repo: Mix.Tasks.Mailglass.Gen.MigrationTest.HostRepo)
           end
           """
  end

  test "rejects ambiguous and unconfigured repo choices before writing" do
    Application.put_env(:mailglass, :ecto_repos, [HostRepo, OtherRepo])

    assert_raise Mix.Error, ~r/exactly one configured Ecto repo/, fn ->
      Mix.Tasks.Mailglass.Gen.Migration.run([])
    end

    assert migration_paths() == []

    assert_raise Mix.Error, ~r/not configured/, fn ->
      Mix.Tasks.Mailglass.Gen.Migration.run(["--repo", "Unknown.Repo"])
    end

    assert migration_paths() == []
  end

  test "keeps an existing initial wrapper byte-for-byte on rerun" do
    Application.put_env(:mailglass, :ecto_repos, [HostRepo])
    Mix.Tasks.Mailglass.Gen.Migration.run([])
    [path] = migration_paths()
    original = File.read!(path)

    assert capture_io(fn -> Mix.Tasks.Mailglass.Gen.Migration.run([]) end) =~ "unchanged"
    assert File.read!(path) == original
  end

  test "adds a rollback-aware offline upgrade without modifying the install wrapper" do
    Application.put_env(:mailglass, :ecto_repos, [HostRepo])
    Mix.Tasks.Mailglass.Gen.Migration.run([])
    [install_path] = migration_paths()
    install_source = File.read!(install_path)

    Mix.Tasks.Mailglass.Gen.Migration.run(["--upgrade", "--from", "4"])

    assert [^install_path, upgrade_path] = migration_paths()
    assert File.read!(install_path) == install_source
    assert upgrade_path =~ "_mailglass_upgrade.exs"

    assert File.read!(upgrade_path) =~
             "def down, do: Mailglass.Migration.down(repo: Mix.Tasks.Mailglass.Gen.MigrationTest.HostRepo, version: 4, non_transactional_wrapper: true)"

    upgrade_source = File.read!(upgrade_path)
    assert upgrade_source =~ "@disable_ddl_transaction true"
    assert upgrade_source =~ "@disable_migration_lock true"
    assert upgrade_source =~ "non_transactional_wrapper: true"
  end

  test "uses the selected repo for live core upgrade inspection despite conflicting package config" do
    Application.put_env(:mailglass, :ecto_repos, [HostRepo])
    prior_repo = Application.get_env(:mailglass, :repo)
    Application.put_env(:mailglass, :repo, OtherRepo)

    on_exit(fn -> restore_repo(:mailglass, prior_repo) end)

    assert capture_io(fn ->
             Mailglass.MigrationGenerator.run(core_spec(), ["--upgrade"],
               with_repo: fn repo, fun ->
                 send(self(), {:started_repo, repo})
                 {:ok, fun.(repo), []}
               end
             )
           end) =~ "created"

    assert_received {:started_repo, HostRepo}
    assert_received {:host_query, query, ["public"], [log: false]}
    assert query =~ "mailglass_events"
    refute_received :other_repo_called

    assert [path] = migration_paths()

    assert File.read!(path) =~
             "def down, do: Mailglass.Migration.down(repo: Mix.Tasks.Mailglass.Gen.MigrationTest.HostRepo, version: 4, non_transactional_wrapper: true)"
  end

  test "keeps migration history unchanged when live startup or metadata inspection fails" do
    Application.put_env(:mailglass, :ecto_repos, [HostRepo])
    prior_repo = Application.get_env(:mailglass, :repo)
    Application.put_env(:mailglass, :repo, HostRepo)

    on_exit(fn -> restore_repo(:mailglass, prior_repo) end)

    assert_raise Mix.Error, ~r/could not inspect the selected repo/, fn ->
      Mailglass.MigrationGenerator.run(core_spec(), ["--upgrade"],
        with_repo: fn _repo, _fun -> {:error, :unavailable} end
      )
    end

    assert migration_paths() == []

    for catalog_result <- [{:error, :database_down}, {:ok, %{rows: [["malformed"]]}}] do
      Process.put(:host_catalog_result, catalog_result)

      assert_raise Mailglass.MigrationVersionError, fn ->
        Mailglass.MigrationGenerator.run(core_spec(), ["--upgrade"],
          with_repo: fn repo, fun -> {:ok, fun.(repo), []} end
        )
      end

      assert migration_paths() == []
    end

    Process.put(:host_catalog_result, {:ok, %{rows: [["6"]]}})

    assert_raise Mix.Error, ~r/no live upgrade is available/, fn ->
      Mailglass.MigrationGenerator.run(core_spec(), ["--upgrade"],
        with_repo: fn repo, fun -> {:ok, fun.(repo), []} end
      )
    end

    assert migration_paths() == []
  after
    Process.delete(:host_catalog_result)
  end

  test "refuses invalid upgrade inputs before writing" do
    Application.put_env(:mailglass, :ecto_repos, [HostRepo])

    for argv <- [
          ["--upgrade", "--from", "0"],
          ["--upgrade", "--from", "6"],
          ["--from", "4"],
          ["--upgrade", "--from", "nope"],
          ["--repair-legacy"]
        ] do
      assert_raise Mix.Error, fn -> Mix.Tasks.Mailglass.Gen.Migration.run(argv) end
      assert migration_paths() == []
    end
  end

  test "refuses a deterministic timestamp collision before replacing an upgrade" do
    Application.put_env(:mailglass, :ecto_repos, [HostRepo])
    now = ~U[2026-08-17 01:00:00Z]
    path = Path.join(migrations_path(), "20260817010000_mailglass_upgrade.exs")
    File.mkdir_p!(Path.dirname(path))
    File.write!(path, "already owned\n")

    assert_raise Mix.Error, ~r/timestamp collision/, fn ->
      Mailglass.MigrationGenerator.run(core_spec(), ["--upgrade", "--from", "4"],
        now: fn -> now end
      )
    end

    assert File.read!(path) == "already owned\n"
  end

  defp migration_paths do
    migrations_path()
    |> Path.join("*.exs")
    |> Path.wildcard()
    |> Enum.sort()
  end

  defp migrations_path, do: Ecto.Migrator.migrations_path(HostRepo)

  defp core_spec do
    %{
      task_name: "mailglass.gen.migration",
      install_suffix: "mailglass_install",
      upgrade_suffix: "mailglass_upgrade",
      install_module_suffix: "MailglassInstall",
      upgrade_module_suffix: "MailglassUpgrade",
      migration_module: Mailglass.Migration,
      initial_version: &Mailglass.Migrations.Postgres.initial_version/0,
      current_version: &Mailglass.Migrations.Postgres.current_version/0
    }
  end

  defp restore_ecto_repos(app, nil), do: Application.delete_env(app, :ecto_repos)
  defp restore_ecto_repos(app, repos), do: Application.put_env(app, :ecto_repos, repos)

  defp restore_repo(app, nil), do: Application.delete_env(app, :repo)
  defp restore_repo(app, repo), do: Application.put_env(app, :repo, repo)
end
