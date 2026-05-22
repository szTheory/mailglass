import Config

# Swoosh 1.25+ requires :api_client to be set at boot. Inbound does not select
# an HTTP client; tests run with the fake. Set false so Swoosh skips init.
config :swoosh, :api_client, false

# Route the MailglassInbound.Repo facade at MailglassInbound.TestRepo so the
# facade resolves in the test env (the facade RAISES when :repo is unset —
# see mailglass_inbound/lib/mailglass_inbound/repo.ex). Host applications set
# their own repo here; mailglass_inbound never owns one outside its own suite.
config :mailglass_inbound, :repo, MailglassInbound.TestRepo

# TestRepo Postgres credentials. Honor MIX_TEST_PARTITION for parallel CI
# partitions; fall back to localhost with standard creds otherwise. Inbound has
# no citext columns, so the core citext-specific prepare/disconnect options are
# intentionally omitted.
config :mailglass_inbound, MailglassInbound.TestRepo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  database: "mailglass_inbound_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10
