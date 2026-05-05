ExUnit.start(exclude: [:skip])

migrations_path =
  :code.priv_dir(:mailglass)
  |> Path.join("repo/migrations")

test_repo_config = Application.get_env(:mailglass, MailglassAdmin.TestRepo)

Application.put_env(
  :mailglass,
  MailglassAdmin.TestRepo,
  Keyword.put(test_repo_config, :pool, DBConnection.ConnectionPool)
)

{:ok, _, _} =
  Ecto.Migrator.with_repo(MailglassAdmin.TestRepo, fn repo ->
    Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
  end)

Application.put_env(:mailglass, MailglassAdmin.TestRepo, test_repo_config)

{:ok, _pid} = MailglassAdmin.TestRepo.start_link()
MailglassAdmin.TestSupport.CitextProbe.run([])
Ecto.Adapters.SQL.Sandbox.mode(MailglassAdmin.TestRepo, :manual)

Application.ensure_all_started(:mailglass)
Application.ensure_all_started(:mailglass_admin)
