defmodule Mix.Tasks.Mailglass.Inbound.Gen.MigrationTest do
  use ExUnit.Case, async: false

  import ExUnit.CaptureIO

  defmodule HostRepo do
    def config,
      do: [otp_app: :mailglass_inbound, priv: "tmp/mailglass_inbound_gen_migration_test/priv/repo"]
  end

  defmodule OtherRepo do
    def config,
      do: [
        otp_app: :mailglass_inbound,
        priv: "tmp/mailglass_inbound_gen_migration_test/priv/other_repo"
      ]
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

             def up, do: MailglassInbound.Migration.up()
             def down, do: MailglassInbound.Migration.down()
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
