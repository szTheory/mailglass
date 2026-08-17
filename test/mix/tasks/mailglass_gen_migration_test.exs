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

  defp migration_paths do
    migrations_path()
    |> Path.join("*.exs")
    |> Path.wildcard()
    |> Enum.sort()
  end

  defp migrations_path, do: Ecto.Migrator.migrations_path(HostRepo)

  defp restore_ecto_repos(app, nil), do: Application.delete_env(app, :ecto_repos)
  defp restore_ecto_repos(app, repos), do: Application.put_env(app, :ecto_repos, repos)
end
