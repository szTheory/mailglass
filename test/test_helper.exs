ExUnit.start()

# TemplateEngine mock. The behaviour module lands in Plan 06; the guard keeps
# `mix test` runnable through Plans 01..05 before the behaviour exists.
if Code.ensure_loaded?(Mailglass.TemplateEngine) do
  Mox.defmock(Mailglass.MockTemplateEngine, for: Mailglass.TemplateEngine)
end

# Phase 2: run mailglass migrations, then start the test Repo so tests can
# check out sandbox connections and query. Mailglass.Migration.up/0 reads the
# pg_class comment on mailglass_events to detect already-applied versions, so
# rerunning is a no-op.
#
# `Ecto.Migrator.with_repo/2` handles "DB doesn't exist" with an actionable
# error message — operators run `mix ecto.create -r Mailglass.TestRepo` once
# as a first-time setup step (documented in CONTRIBUTING.md — Phase 7).
# `with_repo` also stops the ephemeral repo it started after its block returns,
# so we start the TestRepo explicitly for the test run immediately after.
migrations_path =
  :code.priv_dir(:mailglass)
  |> Path.join("repo/migrations")

{:ok, _, _} =
  Ecto.Migrator.with_repo(Mailglass.TestRepo, fn repo ->
    Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
  end)

{:ok, _pid} = Mailglass.TestRepo.start_link()

Ecto.Adapters.SQL.Sandbox.mode(Mailglass.TestRepo, :manual)
