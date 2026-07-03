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

# Pin the schema to "public" so the admin test suite uses the already-migrated
# public schema (pre-2.0 posture). The dedicated FACADE-03 schema-isolation
# render test creates the "mailglass" schema in-process and passes prefix:
# explicitly; the rest of the suite must not inject prefix: "mailglass" and
# then fail to find tables. Mirrors the equivalent pin in core config/test.exs.
config :mailglass, :schema, "public"

# Point the MailglassInbound.Repo facade at the admin test repo so the inbound
# read-models (Internal.Operator.{Records,Timeline,Detail}) and replay seam
# resolve a repo under the admin suite. The facade RAISES when :repo is unset
# (mailglass_inbound/lib/mailglass_inbound/repo.ex). Inbound migrations are run
# against this same DB in test/test_helper.exs so InboundLive fixtures insert.
config :mailglass_inbound, :repo, MailglassAdmin.TestRepo

# Pin the INBOUND schema to "public" too. MailglassInbound.Config.schema/0
# defaults to "mailglass" (not "public"), so without this pin the operator
# LiveView's inbound reads (list_tenants → mailglass_inbound_records) inject
# prefix: "mailglass" and fail with 42P01 because test_helper.exs migrates the
# inbound tables into "public". This mirrors the :mailglass schema pin above —
# the whole admin suite runs against the public-migrated tables; only the
# dedicated FACADE-03 module flips both schemas to "mailglass" in-process.
config :mailglass_inbound, :schema, "public"

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
