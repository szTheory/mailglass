import Config

# Fake adapter for all test runs. Tests that exercise real-provider adapters
# inject {:ok, ...} return shapes via Mox in their own setup blocks.
config :mailglass,
  adapter: {Mailglass.Adapters.Fake, []}

# Phase 2: route mailglass's own Repo facade at Mailglass.TestRepo.
config :mailglass, repo: Mailglass.TestRepo

# Phase 2: single-tenant resolver by default. Adopters who need
# multi-tenancy override this to their own `@behaviour Mailglass.Tenancy` module.
config :mailglass, tenancy: Mailglass.Tenancy.SingleTenant

# TestRepo Postgres credentials. Honor MIX_TEST_PARTITION for parallel
# CI partitions; fall back to localhost with standard creds otherwise.
config :mailglass, Mailglass.TestRepo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  database: "mailglass_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  # `migration_test.exs` drops and recreates the citext extension to prove
  # the down/up round-trip. The fresh OID makes the Postgrex TypeServer's
  # cached type info stale, surfacing as
  # `(Postgrex.Error) XX000 cache lookup failed for type NNNNNN` on the
  # next query that touches `mailglass_suppressions.address` (:citext)
  # from a test file running after migration_test.exs. Auto-disconnecting
  # on `:internal_error` forces the affected connection to reconnect
  # (triggering a fresh type bootstrap) on its next use — test-only;
  # production adopters tune this per their failover policy.
  disconnect_on_error_codes: [:internal_error]

# Suppress the boot-time "Oban not loaded" warning in test output.
config :logger, level: :warning
