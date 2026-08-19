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
#
# **Dual-schema alignment (D-12 / INB-03):**
# Read MAILGLASS_SCHEMA from the environment (default "public" when unset or
# empty, mirroring core config/runtime.exs semantics). Three alignment steps:
#
#   1. Set `config :mailglass_inbound, :schema` to the target schema so
#      `Config.schema/0` reads the right value after the cache reset.
#   2. Erase the `{MailglassInbound.Config, :schema}` `:persistent_term` key so
#      `Config.schema/0` re-warms from the updated app env on its next call,
#      not from the stale "public" boot-warmed value.
#   3. When schema != "public", add `parameters: [search_path: schema]` to the
#      TestRepo Postgrex connection config so that raw SQL (TRUNCATE TABLE,
#      query!/2 without an explicit schema qualifier) targets the correct schema.
#      This is needed because Ecto's `:prefix` option only applies to
#      Ecto-DSL calls (insert/one/all), not raw query!/2 SQL. Tests that
#      TRUNCATE the inbound tables must hit the migrated schema, not "public".
#      For schema == "public", the Postgres default search_path ($user, public)
#      already resolves to public — no override needed.
#
# **Migration runner requirement:** `Migrations.Postgres` uses `use Ecto.Migration`
# and calls `execute/1` / `create/1`, which require an active
# `Ecto.Migration.Runner` process. That runner is started by `Ecto.Migrator.up/4`.
# We drive migration by defining an inline wrapper migration and calling
# `Ecto.Migrator.up(repo, version, WrapperModule)` inside the `with_repo` block —
# the same pattern `migrations_test.exs` uses. The version slot is derived from
# the package's internal migration version so adding V02+ reruns the test
# install wrapper against an existing developer/CI database. A fixed slot
# would leave its physical schema stale while newly compiled queries expect
# the latest columns.
#
# CREATE SCHEMA runs as the first statement inside with_repo (before Sandbox.mode
# and any test checkout), so the schema exists before the SQL Sandbox owner
# starts — the schema-must-exist-before-Sandbox-owner footgun is resolved
# structurally (footgun 13 / T-135-06).

schema =
  case System.get_env("MAILGLASS_SCHEMA") do
    s when is_binary(s) and s != "" -> s
    _ -> "public"
  end

# 1. Align the app env so Config.schema/0 re-warms to the target schema.
Application.put_env(:mailglass_inbound, :schema, schema)

# 2. Erase the persistent_term cache so Config.schema/0 re-reads from app env
#    rather than serving the stale boot-warmed value (which was "public" from
#    the compile-time config/test.exs pin set in Plan 01). Any subsequent call
#    to Config.schema/0 self-heals by warm_schema/0 and writes `schema` back.
:persistent_term.erase({MailglassInbound.Config, :schema})

# 3. Define the inline wrapper migration that drives Migration.up/1 inside the
#    active Ecto.Migration.Runner context set up by Ecto.Migrator.up/4.
defmodule MailglassInbound.TestMigration.Install do
  @moduledoc false
  use Ecto.Migration

  def up do
    MailglassInbound.Migration.up(
      prefix: Application.get_env(:mailglass_inbound, :schema, "public"),
      repo: MailglassInbound.TestRepo
    )
  end

  def down, do: :ok
end

test_repo_config = Application.get_env(:mailglass_inbound, MailglassInbound.TestRepo)

install_version =
  99_000_000_000_000 + MailglassInbound.Migrations.Postgres.current_version()

# 4. For non-public schemas, update the TestRepo Postgrex connection parameters
#    to set search_path = schema. This ensures raw SQL queries (e.g.
#    `TRUNCATE TABLE mailglass_inbound_records CASCADE` in test setup blocks)
#    target the correct schema rather than the Postgres default "public". For
#    the default "public" schema, the Postgres default search_path already
#    resolves correctly, so no override is applied.
patched_config =
  if schema != "public" do
    parameters = Keyword.get(test_repo_config, :parameters, [])
    new_parameters = Keyword.put(parameters, :search_path, schema)
    Keyword.put(test_repo_config, :parameters, new_parameters)
  else
    test_repo_config
  end

Application.put_env(
  :mailglass_inbound,
  MailglassInbound.TestRepo,
  Keyword.put(patched_config, :pool, DBConnection.ConnectionPool)
)

{:ok, _, _} =
  Ecto.Migrator.with_repo(MailglassInbound.TestRepo, fn repo ->
    # Ecto's migrator creates its `schema_migrations` bookkeeping table BEFORE
    # running any migration body. The TestRepo connection already carries
    # `search_path = <schema>` (patched above), so for a non-public schema that
    # does not physically exist yet, that first DDL fails with 3F000
    # (invalid_schema_name) — the migration body's own CREATE SCHEMA never gets
    # a chance to run. Create the schema up front (CREATE SCHEMA is
    # search_path-independent) so both schema_migrations and the migration body
    # land in the target schema.
    if schema != "public" do
      Ecto.Adapters.SQL.query!(repo, ~s(CREATE SCHEMA IF NOT EXISTS "#{schema}"))
    end

    # Developer test databases can outlive package versions. If an old or
    # interrupted test install left package tables without the version anchor,
    # the production dispatcher correctly fails closed. The test database is
    # disposable, so recover it by removing only the three inbound-owned
    # tables before the version-derived install wrapper runs.
    Mailglass.Identifier.validate!(schema, :prefix)

    anchor =
      Ecto.Adapters.SQL.query!(
        repo,
        """
        SELECT pg_catalog.obj_description(pg_class.oid, 'pg_class')
        FROM pg_class
        LEFT JOIN pg_namespace ON pg_namespace.oid = pg_class.relnamespace
        WHERE pg_class.relname = 'mailglass_inbound_records'
        AND pg_namespace.nspname = $1
        """,
        [schema]
      ).rows

    if anchor in [[], [[nil]]] do
      quoted_schema = inspect(schema)

      for table <- [
            "mailglass_inbound_replay_runs",
            "mailglass_inbound_evidence",
            "mailglass_inbound_records"
          ] do
        Ecto.Adapters.SQL.query!(repo, "DROP TABLE IF EXISTS #{quoted_schema}.#{table} CASCADE")
      end
    end

    Ecto.Migrator.up(repo, install_version, MailglassInbound.TestMigration.Install, log: false)
  end)

# Restore original config (including the search_path patch for the long-lived
# TestRepo pool that test bodies use — Sandbox connections inherit the search_path
# set at pool startup).
Application.put_env(:mailglass_inbound, MailglassInbound.TestRepo, patched_config)

{:ok, _pid} = MailglassInbound.TestRepo.start_link()

# When running under a non-public schema, Ecto.Migrator.up/4 in migrations_test.exs
# records version slots in `<schema>.schema_migrations` (because search_path resolves
# there). Those test cleanup blocks only delete from `public.schema_migrations`, so
# the non-public `schema_migrations` table accumulates leftover entries across runs.
# On the next run, System.unique_integer/1 produces the same small monotonic values
# (same test seeds), matching stale entries — causing Ecto.Migrator to skip those
# migrations (version already applied). Result: CREATE SCHEMA never fires and
# migrations_test.exs assertions fail.
#
# Fix: after TestRepo starts, purge stale test-version entries from the non-public
# `schema_migrations` table (keeping only the current package-version-derived
# install slot, which is legitimate and stable until the next internal version).
if schema != "public" do
  MailglassInbound.TestRepo.query!(
    "DELETE FROM schema_migrations WHERE version != $1",
    [install_version]
  )
end

Ecto.Adapters.SQL.Sandbox.mode(MailglassInbound.TestRepo, :manual)

ExUnit.start()
