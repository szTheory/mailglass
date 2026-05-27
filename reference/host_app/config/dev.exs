import Config

config :mailglass_reference_host, MailglassReferenceHost.Repo,
  username: System.get_env("PGUSER", "postgres"),
  password: System.get_env("PGPASSWORD", "postgres"),
  hostname: System.get_env("PGHOST", "localhost"),
  port: String.to_integer(System.get_env("PGPORT", "5432")),
  database: System.get_env("PGDATABASE", "mailglass_reference_host_dev"),
  show_sensitive_data_on_connection_error: true,
  stacktrace: true,
  pool_size: 10
