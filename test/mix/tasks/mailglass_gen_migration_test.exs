defmodule Mix.Tasks.Mailglass.Gen.MigrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  defmodule HostRepo do
    def config, do: [otp_app: :mailglass, priv: "tmp/mailglass_gen_migration_test/priv/repo"]
  end

  defmodule OtherRepo do
    def config, do: [otp_app: :mailglass, priv: "tmp/mailglass_gen_migration_test/priv/other_repo"]
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

             def up, do: Mailglass.Migration.up()
             def down, do: Mailglass.Migration.down()
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
    assert File.read!(upgrade_path) =~ "def down, do: Mailglass.Migration.down(version: 4)"
  end

  test "refuses invalid upgrade inputs before writing" do
    Application.put_env(:mailglass, :ecto_repos, [HostRepo])

    for argv <- [
          ["--upgrade", "--from", "0"],
          ["--upgrade", "--from", "5"],
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
end
