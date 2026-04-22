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
  pool_size: 10

# Suppress the boot-time "Oban not loaded" warning in test output.
config :logger, level: :warning
