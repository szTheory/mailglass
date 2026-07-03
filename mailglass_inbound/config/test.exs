import Config

# Swoosh 1.25+ requires :api_client to be set at boot. Inbound does not select
# an HTTP client; tests run with the fake. Set false so Swoosh skips init.
config :swoosh, :api_client, false

# Route the MailglassInbound.Repo facade at MailglassInbound.TestRepo so the
# facade resolves in the test env (the facade RAISES when :repo is unset —
# see mailglass_inbound/lib/mailglass_inbound/repo.ex). Host applications set
# their own repo here; mailglass_inbound never owns one outside its own suite.
config :mailglass_inbound, :repo, MailglassInbound.TestRepo

# Pin :schema to "public" in the test env so the facade injects prefix:"public"
# and all test DB inserts/reads hit the schema where migrations ran. Mirrors
# config/test.exs in core mailglass (see Phase 133). The dedicated schema-isolation
# test (repo_prefix_test.exs) overrides this per-test to a non-public name, then
# erases the :persistent_term cache so Config.schema/0 re-reads from app env.
config :mailglass_inbound, :schema, "public"

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

# Neutralize the post-verify ingress rate limiter (IOPS-04) by default in the
# test env. The limiter is always-on in production with sensible defaults
# (tenant 1000/min, recipient 500/min, sender_domain 200/min), but it reads ONE
# node-local ETS table (:mailglass_inbound_rate_limit) shared across the whole
# suite. Unrelated ingress tests (e.g. telemetry_test) drive many requests that
# share a sender_domain/tenant and would otherwise drain a bucket and trip 429s
# in a later, order-dependent test. Effectively-unlimited capacities make the
# limiter inert for incidental traffic. The dedicated rate-limit tests
# (RateLimiterTest, plug_test "ingress rate limiter" describe) override these
# per-test with tiny capacities AND reset the ETS table, so tripping is still
# fully exercised.
#
# WR-01: per_minute == capacity here mirrors the core Mailglass.RateLimiter
# convention (sustained refill == burst size). With a huge per_minute the bucket
# also refills instantly, reinforcing the "inert for incidental traffic" intent.
config :mailglass_inbound, :rate_limit,
  tenant: [capacity: 1_000_000, per_minute: 1_000_000],
  recipient: [capacity: 1_000_000, per_minute: 1_000_000],
  sender_domain: [capacity: 1_000_000, per_minute: 1_000_000]
