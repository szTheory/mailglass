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
  # Recompile the mailglass sibling packages in place on each request. By
  # default Phoenix's code reloader only recompiles the demo app's own code, so
  # edits to these PATH deps would otherwise need a full container restart
  # (`make demo-down && make demo`). With this, editing library source +
  # hard-refreshing the browser is enough — the reloader is pull-based (it
  # checks file mtimes on each request), so it works over the Docker bind mount
  # where fsevents-based file watchers do not.
  reloadable_apps: [:mailglass, :mailglass_admin, :mailglass_inbound, :mailglass_demo],
  debug_errors: true,
  secret_key_base: String.duplicate("mailglass_demo_dev_secret_key_base_", 2),
  server: true

config :logger, level: :info
