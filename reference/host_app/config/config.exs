import Config

config :mailglass_reference_host,
  ecto_repos: [MailglassReferenceHost.Repo]

config :mailglass_reference_host, MailglassReferenceHost.Repo,
  migration_timestamps: [type: :utc_datetime_usec]

config :mailglass_reference_host, :dev_routes, false
