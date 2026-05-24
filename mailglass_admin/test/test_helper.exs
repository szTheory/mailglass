ExUnit.start(exclude: [:skip])

core_migrations_path =
  :code.priv_dir(:mailglass)
  |> Path.join("repo/migrations")

# Inbound migrations land in the SAME admin test DB so InboundLive-suite
# fixtures (InboundRecord + InboundEvidence + ExecutionRun) can be inserted via
# MailglassInbound.InboundRecords.insert_* against MailglassAdmin.TestRepo
# (config :mailglass_inbound, :repo, MailglassAdmin.TestRepo — config/test.exs).
inbound_migrations_path =
  :code.priv_dir(:mailglass_inbound)
  |> Path.join("repo/migrations")

test_repo_config = Application.get_env(:mailglass, MailglassAdmin.TestRepo)

# Pool override for the migration phase: TestRepo is configured with the Sandbox
# pool so test bodies can checkout/checkin, but Sandbox needs mode/2 (set to
# :manual below, after migrations) before checkouts work — leaving it as Sandbox
# during with_repo makes the migrator's checkout hang. Override to the default
# ConnectionPool for migrations, then restore the Sandbox config.
Application.put_env(
  :mailglass,
  MailglassAdmin.TestRepo,
  Keyword.put(test_repo_config, :pool, DBConnection.ConnectionPool)
)

{:ok, _, _} =
  Ecto.Migrator.with_repo(MailglassAdmin.TestRepo, fn repo ->
    Ecto.Migrator.run(repo, core_migrations_path, :up, all: true, log: false)
    Ecto.Migrator.run(repo, inbound_migrations_path, :up, all: true, log: false)
  end)

Application.put_env(:mailglass, MailglassAdmin.TestRepo, test_repo_config)

{:ok, _pid} = MailglassAdmin.TestRepo.start_link()
MailglassAdmin.TestSupport.CitextProbe.run([])
Ecto.Adapters.SQL.Sandbox.mode(MailglassAdmin.TestRepo, :manual)

Application.ensure_all_started(:mailglass)
Application.ensure_all_started(:mailglass_admin)
Application.ensure_all_started(:mailglass_inbound)
