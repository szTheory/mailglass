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
#
# **Pool override for migration phase:** TestRepo is configured with
# `pool: Ecto.Adapters.SQL.Sandbox` (config/test.exs) so test bodies can
# `Sandbox.checkout/checkin`. But Sandbox needs `mode/2` to be set before
# checkouts work, and we set `:manual` only AFTER migrations finish. If we
# leave the pool as Sandbox during `with_repo`, the migrator's connection
# checkout hangs and times out (`DBConnection.ConnectionError ... request
# was dropped from queue after 5998ms`). Override the pool to the default
# `DBConnection.ConnectionPool` for the migration step, then restore the
# Sandbox pool config for the long-lived TestRepo that test bodies use.
migrations_path =
  :code.priv_dir(:mailglass)
  |> Path.join("repo/migrations")

test_repo_config = Application.get_env(:mailglass, Mailglass.TestRepo)

# Schema-isolation matrix support (D-06 / Success Criterion 7). config/runtime.exs
# maps MAILGLASS_SCHEMA onto `config :mailglass, :schema`; the default suite keeps
# the config/test.exs "public" pin. For a non-public schema the whole suite must
# actually run there: the migrations' unqualified DDL and the raw-SQL test setup
# need `search_path = <schema>` on the connection (the facade's `prefix:` injection
# already routes Ecto queries), and the schema must be created before the migrator
# writes its `schema_migrations` bookkeeping table (else CREATE TABLE fails with
# 3F000 under the isolated search_path).
schema = Mailglass.Config.schema()

# search_path is "<schema>, public": unqualified DDL/queries resolve to the
# isolated schema first, but the `citext` extension type (installed in public)
# stays resolvable. Mirrors the admin operator harness's `SET LOCAL search_path
# TO <schema>, public`.
migration_parameters =
  if schema != "public" do
    test_repo_config
    |> Keyword.get(:parameters, [])
    |> Keyword.put(:search_path, "#{schema}, public")
  else
    Keyword.get(test_repo_config, :parameters, [])
  end

Application.put_env(
  :mailglass,
  Mailglass.TestRepo,
  test_repo_config
  |> Keyword.put(:pool, DBConnection.ConnectionPool)
  |> Keyword.put(:parameters, migration_parameters)
)

{:ok, _, _} =
  Ecto.Migrator.with_repo(Mailglass.TestRepo, fn repo ->
    if schema != "public" do
      Ecto.Adapters.SQL.query!(repo, ~s(CREATE SCHEMA IF NOT EXISTS "#{schema}"))
    end

    Ecto.Migrator.run(repo, migrations_path, :up, all: true, log: false)
  end)

# Restore the Sandbox pool config for the long-lived TestRepo, keeping the
# search_path patch so test-body Sandbox connections resolve unqualified raw SQL
# to the isolated schema (Sandbox connections inherit the search_path set at pool
# startup).
restored_test_repo_config =
  if schema != "public" do
    Keyword.put(test_repo_config, :parameters, migration_parameters)
  else
    test_repo_config
  end

Application.put_env(:mailglass, Mailglass.TestRepo, restored_test_repo_config)

{:ok, _pid} = Mailglass.TestRepo.start_link()

# Phase 3 (Plan 10): ensure oban_jobs table exists for @tag oban: :manual tests.
# Oban.Migrations.up/0 must execute inside an Ecto migration runner; the helper
# wraps it in a test-only migration so failures surface during suite startup.
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
Mailglass.TestSupport.CitextProbe.run([])

Ecto.Adapters.SQL.Sandbox.mode(Mailglass.TestRepo, :manual)
