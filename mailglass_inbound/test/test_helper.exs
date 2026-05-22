Application.put_env(:swoosh, :api_client, false, persistent: true)

# Run the inbound migrations, then start the test Repo so tests can check out
# sandbox connections and query against a real Postgres database (the ingress
# dedupe unique index is the anchor for the replay-convergence property).
#
# `Ecto.Migrator.with_repo/2` handles "DB doesn't exist" with an actionable
# error — operators run `mix ecto.create -r MailglassInbound.TestRepo` once as a
# first-time setup step (CI does this in the inbound Postgres job). `with_repo`
# also stops the ephemeral repo it started after its block returns, so we start
# the TestRepo explicitly for the test run immediately after.
#
# **Pool override for migration phase:** TestRepo is configured with
# `pool: Ecto.Adapters.SQL.Sandbox` (config/test.exs) so test bodies can
# `Sandbox.checkout/checkin`. But Sandbox needs `mode/2` set before checkouts
# work, and we set `:manual` only AFTER migrations finish. Leaving the pool as
# Sandbox during `with_repo` makes the migrator's connection checkout hang and
# time out. Override the pool to the default `DBConnection.ConnectionPool` for
# the migration step, then restore the Sandbox pool config for the long-lived
# TestRepo that test bodies use.
migrations_path =
  :code.priv_dir(:mailglass_inbound)
  |> Path.join("repo/migrations")

test_repo_config = Application.get_env(:mailglass_inbound, MailglassInbound.TestRepo)

Application.put_env(
  :mailglass_inbound,
  MailglassInbound.TestRepo,
  Keyword.put(test_repo_config, :pool, DBConnection.ConnectionPool)
)

{:ok, _, _} =
  Ecto.Migrator.with_repo(MailglassInbound.TestRepo, fn repo ->
    Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
  end)

Application.put_env(:mailglass_inbound, MailglassInbound.TestRepo, test_repo_config)

{:ok, _pid} = MailglassInbound.TestRepo.start_link()

Ecto.Adapters.SQL.Sandbox.mode(MailglassInbound.TestRepo, :manual)

ExUnit.start()
