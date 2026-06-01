import Config

config :mailglass_demo, MailglassDemo.Repo,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost"),
  port: String.to_integer(System.get_env("PGPORT", "5432")),
  database: System.get_env("PGDATABASE", "mailglass_demo_dev"),
  stacktrace: true,
  show_sensitive_data_on_connection_error: true,
  pool_size: 10

config :mailglass_demo, MailglassDemoWeb.Endpoint,
  http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4015"))],
  check_origin: false,
  code_reloader: true,
  debug_errors: true,
  secret_key_base: String.duplicate("mailglass_demo_dev_secret_key_base_", 2),
  server: true

config :logger, level: :info
