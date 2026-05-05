import Config

# Mailglass core test runtime for the sibling package's own test suite.
config :mailglass,
  adapter: {Mailglass.Adapters.Fake, []},
  repo: MailglassAdmin.TestRepo,
  tenancy: Mailglass.Tenancy.SingleTenant,
  suppression_store: Mailglass.SuppressionStore.Ecto,
  async_adapter: :task_supervisor,
  adapter_endpoint: "mailglass-test-endpoint"

config :mailglass, MailglassAdmin.TestRepo,
  username: System.get_env("POSTGRES_USER", "postgres"),
  password: System.get_env("POSTGRES_PASSWORD", "postgres"),
  hostname: System.get_env("POSTGRES_HOST", "localhost"),
  database: "mailglass_test#{System.get_env("MIX_TEST_PARTITION")}",
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  prepare: :unnamed,
  disconnect_on_error_codes: [:internal_error]

config :mailglass, :tracking,
  host: "localhost:4000",
  salts: ["test-salt"]

# Synthetic adopter endpoint for router + LiveView test coverage.
# See test/support/endpoint_case.ex. The `secret_key_base` literal is
# 72 chars (>= Phoenix's 64-byte minimum).
#
# `pubsub_server: Mailglass.PubSub` — Plan 06's LiveReload test
# (preview_live_test.exs line 138) broadcasts on `Mailglass.PubSub`,
# so the synthetic endpoint points there. `Mailglass.PubSub` is started
# by the mailglass core application's supervisor, which boots when
# `:mailglass` loads. The earlier choice of `MailglassAdmin.TestPubSub`
# (Plan 02) was never started by any supervisor and never carried
# adopter broadcasts — Plan 06 corrects the mismatch.
config :mailglass_admin, MailglassAdmin.TestAdopter.Endpoint,
  http: [port: 4002],
  server: false,
  secret_key_base: String.duplicate("mailglass_admin_test_secret_key_base_0", 2),
  live_view: [signing_salt: "mailglass_admin_test_signing_salt_0123"],
  pubsub_server: Mailglass.PubSub,
  render_errors: [formats: [html: MailglassAdmin.TestAdopter.ErrorHTML], layout: false]

config :logger, level: :warning
