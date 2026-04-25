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

# Phase 3 (Plan 10): ensure oban_jobs table exists for @tag oban: :manual tests.
# Oban.Migrations.up/0 is idempotent (IF NOT EXISTS semantics) — safe on warm DB.
# No-op when Oban is not in deps (Code.ensure_loaded? guard inside the helper).
Mailglass.ObanHelpers.maybe_create_oban_jobs()

# Warm the citext OID cache on a fresh connection right after migrations.
#
# Root cause: `mix ecto.drop && mix ecto.create` (or migration_test.exs's
# down-then-up round-trip) causes Postgres to assign citext a new OID.
# Postgrex workers and the shared TypeServer retain the pre-drop OID in
# cache. The first query that touches a citext column (e.g.
# mailglass_suppressions.address) surfaces as:
#
#   (Postgrex.Error) ERROR XX000 (internal_error)
#   cache lookup failed for type NNNNNN
#
# `disconnect_on_error_codes: [:internal_error]` in config/test.exs converts
# that error into a pool disconnect so the next checkout reconnects and
# re-registers all types against the live DB. This probe fires the stale-OID
# error proactively at suite startup, before any test runs.
#
# For the mid-run case (migration_test.exs drops and recreates citext during
# the suite), DataCase.setup and MailerCase.setup each run this same probe on
# every sandbox checkout, so the connection used by each test body is already
# clean before the test runs.
try do
  Mailglass.TestRepo.query!("SELECT 'probe'::citext")
rescue
  # disconnect_on_error_codes fires; next connection is clean
  Postgrex.Error -> :ok
end

Ecto.Adapters.SQL.Sandbox.mode(Mailglass.TestRepo, :manual)
