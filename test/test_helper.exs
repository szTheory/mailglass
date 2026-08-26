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

# HARNESS-01 (D-09): register the pool-hygiene ledger formatter alongside the
# default CLI formatter. Deliberately NOT the `--formatter` CLI flag, which
# *replaces* ExUnit's default formatter list — that would silently drop
# `ExUnit.CLIFormatter`'s normal test/failure output.
ExUnit.configure(formatters: [ExUnit.CLIFormatter, Mailglass.TestSupport.SuiteTruthFormatter])
Mailglass.TestSupport.TimeoutEvidence.initialize!()

# HARNESS-03 (D-13, D-15): register the anti-vacuity policy check. Placed
# here (after `schema` above, alongside the formatter it reads via
# `SuiteTruthFormatter.current_state/0`) so the report it prints at
# `ExUnit.after_suite/1` already has both inputs available. Reporting always
# runs; enforcement is opt-in behind `MAILGLASS_SUITE_FLOOR` — see
# `Mailglass.TestSupport.SuiteFloor`'s moduledoc.
Mailglass.TestSupport.SuiteFloor.install()

# On any non-public schema axis, exclude `:public_only` tests. These are
# generic, ambient-schema round-trip tests (e.g. migration_test.exs's `down/0`
# describe) whose isolation-path coverage is provided separately by
# `:schema_isolation`-tagged siblings. On the mailglass axis the harness
# connection search_path + Sandbox :auto makes their full `Ecto.Migrator.run(
# :down, all: true)` deadlock on `lock_for_migrations` — and they add no
# isolation coverage — so they run only on the public axis where they validate
# the adopter `mix ecto.rollback` path.
if schema != "public" do
  ExUnit.configure(exclude: [:public_only])
end

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

    # citext MUST live in `public`, explicitly. v01 issues a deliberately
    # UNqualified `CREATE EXTENSION IF NOT EXISTS citext` (postgres/v01.ex:18,
    # "citext installs into public so a second install in another schema can
    # share it"), and `CREATE EXTENSION` with no `SCHEMA` clause installs into
    # the FIRST schema of the connection's search_path — which, on a non-public
    # axis with the `"<schema>, public"` patch above, is the isolated schema, not
    # `public`. On a freshly created database that is the very first statement to
    # create citext, so the extension landed in `<schema>` and the comment above
    # ("the citext extension type (installed in public) stays resolvable") was
    # simply false on the schema-isolation axis.
    #
    # That silently held together only while every prefixed-schema test used the
    # literal `"mailglass"` as its own scratch prefix, so their
    # `search_path = "mailglass, public"` pins happened to include the schema
    # citext had landed in. The moment those tests moved to scratch prefixes of
    # their own (143 gap closure), `add(:address, :citext)` under
    # `search_path = "<scratch>, public"` could no longer resolve the type and
    # raised `42704 (undefined_object) type "citext" does not exist`.
    #
    # Pinning the extension to `public` here makes the harness match its own
    # documented invariant on BOTH axes. Idempotent: `IF NOT EXISTS` is a no-op
    # when citext already exists (it does not relocate an existing extension), so
    # this only decides the location on a fresh database.
    Ecto.Adapters.SQL.query!(repo, "CREATE EXTENSION IF NOT EXISTS citext SCHEMA public")

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

# `caller:` is passed explicitly (there is no `__MODULE__` in a script, and it
# is never inferred — see SandboxOwnership's "Caller attribution" moduledoc
# section) so a refusal here names the suite boot rather than the helper.
Mailglass.TestSupport.SandboxOwnership.mode_manual!(Mailglass.TestRepo,
  caller: "test/test_helper.exs (suite boot)"
)
