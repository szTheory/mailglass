import Config

if config_env() == :prod do
  database_url =
    System.get_env("DATABASE_URL") ||
      raise "DATABASE_URL is required for the Mailglass demo app in prod"

  config :mailglass_demo, MailglassDemo.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE", "10"))

  config :mailglass_demo, MailglassDemoWeb.Endpoint,
    http: [ip: {0, 0, 0, 0}, port: String.to_integer(System.get_env("PORT", "4015"))],
    secret_key_base: System.fetch_env!("SECRET_KEY_BASE"),
    server: true
end
