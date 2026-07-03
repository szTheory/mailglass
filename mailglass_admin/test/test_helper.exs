ExUnit.start(exclude: [:skip])

core_migrations_path =
  :code.priv_dir(:mailglass)
  |> Path.join("repo/migrations")

# Inbound tables land in the SAME admin test DB so InboundLive-suite fixtures
# (InboundRecord + InboundEvidence + ExecutionRun) and the operator overview's
# list_tenants read (mailglass_inbound_records) resolve against
# MailglassAdmin.TestRepo (config :mailglass_inbound, :repo — config/test.exs).
#
# Inbound ships NO priv/repo/migrations directory — its schema is created
# programmatically via MailglassInbound.Migration.up/1, which composes a NESTED
# Migrations.Postgres runner. So we CANNOT point Ecto.Migrator.run at a
# migrations path (there is none). Instead we drive it with an inline wrapper
# migration under its own Ecto.Migrator.up version slot, mirroring the canonical
# pattern in mailglass_inbound/test/test_helper.exs. The prefix is read from
# config (:mailglass_inbound, :schema — pinned "public" in config/test.exs) so
# the admin suite's inbound tables land in the same schema its reads target.
defmodule MailglassAdmin.TestSupport.InboundInstallMigration do
  @moduledoc false
  use Ecto.Migration

  def up do
    MailglassInbound.Migration.up(
      prefix: Application.get_env(:mailglass_inbound, :schema, "public"),
      repo: MailglassAdmin.TestRepo
    )
  end

  def down, do: :ok
end

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

    # Inbound schema via its programmatic installer under a dedicated version
    # slot (large enough not to collide with any core migration timestamp).
    Ecto.Migrator.up(
      repo,
      99_000_000_000_001,
      MailglassAdmin.TestSupport.InboundInstallMigration,
      log: false
    )
  end)

Application.put_env(:mailglass, MailglassAdmin.TestRepo, test_repo_config)

{:ok, _pid} = MailglassAdmin.TestRepo.start_link()
MailglassAdmin.TestSupport.CitextProbe.run([])
Ecto.Adapters.SQL.Sandbox.mode(MailglassAdmin.TestRepo, :manual)

Application.ensure_all_started(:mailglass)
Application.ensure_all_started(:mailglass_admin)
Application.ensure_all_started(:mailglass_inbound)
