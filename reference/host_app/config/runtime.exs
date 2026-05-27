import Config

if config_env() == :dev do
  database_url =
    System.get_env("DATABASE_URL") || "ecto://postgres:postgres@localhost/mailglass_reference_host_dev"

  config :mailglass_reference_host, MailglassReferenceHost.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10")
end
