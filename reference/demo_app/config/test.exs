import Config

config :mailglass_demo, MailglassDemo.Repo,
  username: System.get_env("PGUSER", System.get_env("POSTGRES_USER", "postgres")),
  password: System.get_env("PGPASSWORD", System.get_env("POSTGRES_PASSWORD", "postgres")),
  hostname: System.get_env("PGHOST", System.get_env("POSTGRES_HOST", "localhost")),
  port: String.to_integer(System.get_env("PGPORT", "5432")),
  database:
    System.get_env("PGDATABASE", "mailglass_demo_test#{System.get_env("MIX_TEST_PARTITION")}"),
  pool: Ecto.Adapters.SQL.Sandbox,
  pool_size: 10,
  prepare: :unnamed

config :mailglass_demo, MailglassDemoWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: String.to_integer(System.get_env("PORT", "4016"))],
  secret_key_base: String.duplicate("mailglass_demo_test_secret_key_base_", 2),
  server: false

config :logger, level: :warning
